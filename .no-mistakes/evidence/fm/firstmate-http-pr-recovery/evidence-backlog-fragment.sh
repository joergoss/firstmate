# Product-level evidence for close recovery, retained deliverables, and landed projection.
case_dir=$(make_home evidence-http-forgejo-close)
id=evidence-http-forgejo-close
retained_id=evidence-http-forgejo-retained
pr_url=http://pi4:3001/joergoss/Scan2Excel/pulls/7
add_item "$case_dir" "$id"
start_item "$case_dir" "$id"
printf 'id=%s\ndata=%s\nspawn_gen=spawn-evidence-http\narg=--pr\narg=%s\n' \
  "$id" "$(home_of "$case_dir")/data" "$pr_url" > "$(home_of "$case_dir")/state/$id.backlog-close"
real_tasks_axi=$(command -v tasks-axi)
cat > "$case_dir/fakebin/tasks-axi" <<SH
#!/usr/bin/env bash
previous=
for arg in "\$@"; do
  if [ "\$previous" = --pr ] \
    && ! [[ "\$arg" =~ ^https://github\.com/[^/]+/[^/]+/pull/[0-9]+\$ ]] \
    && ! [[ "\$arg" =~ ^https://[^/:]+/[^/]+/[^/]+/pulls/[0-9]+\$ ]]; then
    printf 'error: Task pr link must be a canonical pull request URL\n'
    exit 1
  fi
  previous=\$arg
done
exec "$real_tasks_axi" "\$@"
SH
chmod +x "$case_dir/fakebin/tasks-axi"
run_bootstrap "$case_dir" > /dev/null || fail "HTTP close replay failed"
[ "$(row_state "$case_dir" "$id")" = done ] || fail "HTTP close did not finish"
add_item "$case_dir" "$retained_id"
start_item "$case_dir" "$retained_id"
FM_HOME="$(home_of "$case_dir")" PATH="$case_dir/fakebin:$PATH" \
  bash -c '. "$1/bin/fm-tasks-axi-lib.sh"; . "$1/bin/fm-backlog-transition-lib.sh"; fm_backlog_retain "$2" "$3" --pr "$4"' \
  _ "$ROOT" "$(home_of "$case_dir")/data" "$retained_id" "$pr_url" || fail "retained deliverable failed"
tasks-axi done "$retained_id" --file "$(backlog_of "$case_dir")" > /dev/null || fail "retained row close failed"
snapshot=$(FM_ROOT_OVERRIDE="$ROOT" FM_HOME="$(home_of "$case_dir")" PATH="$case_dir/fakebin:$PATH" \
  "$ROOT/bin/fm-fleet-snapshot.sh" --json) || fail "snapshot failed"
printf '%s' "$snapshot" | jq -e --arg id "$id" --arg retained "$retained_id" --arg url "$pr_url" \
  'any(.backlog.records[]; .id == $id and .pr_url == $url and .completion.verb == "merged")
   and any(.backlog.records[]; .id == $retained and .pr_url == $url and .completion.verb == "merged")' > /dev/null \
  || fail "generated close notes lost their PR projection"
landed=$(FM_ROOT_OVERRIDE="$ROOT" FM_HOME="$(home_of "$case_dir")" PATH="$case_dir/fakebin:$PATH" \
  "$ROOT/bin/fm-fleet-snapshot.sh" --secondmate-home-summary) || fail "landed projection failed"
printf '%s' "$landed" | jq -e --arg id "$id" --arg retained "$retained_id" --arg url "$pr_url" \
  'any(.landed[]; .id == $id and .pr_url == $url)
   and any(.landed[]; .id == $retained and .pr_url == $url)' > /dev/null \
  || fail "landed projection lost its PR URL"
printf '$ tasks-axi show <closed-http-task> --full\n'
tasks-axi show "$id" --file "$(backlog_of "$case_dir")" --full | grep -E '(id|state|body|links):'
printf '\n$ tasks-axi show <retained-http-task> --full\n'
tasks-axi show "$retained_id" --file "$(backlog_of "$case_dir")" --full | grep -E '(id|state|body|links):'
printf '\n$ bin/fm-fleet-snapshot.sh --json (selected backlog records)\n'
printf '%s' "$snapshot" | jq --arg id "$id" --arg retained "$retained_id" \
  '[.backlog.records[] | select(.id == $id or .id == $retained) | {id,state,pr_url,completion,body_lines}]'
printf '\n$ bin/fm-fleet-snapshot.sh --secondmate-home-summary (selected landed rows)\n'
printf '%s' "$landed" | jq --arg id "$id" --arg retained "$retained_id" \
  '[.landed[] | select(.id == $id or .id == $retained) | {id,pr_url,what}]'
