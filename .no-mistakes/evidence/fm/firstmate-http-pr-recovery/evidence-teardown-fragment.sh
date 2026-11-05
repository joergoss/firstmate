# Product-level evidence for parked-run recovery with an HTTP Forgejo PR URL.
case_dir=$(make_case evidence-http-parked-run)
write_meta "$case_dir" no-mistakes ship
land_shippable_commit "$case_dir"
anchor_short=$(git -C "$case_dir/wt" rev-parse --short=7 HEAD)
advanced_short=$(make_unfetched_pipeline_heads "$case_dir")
rc=0
FM_FAKE_AXI_STATUS="$(parked_axi_status_toon fm/task-x1 "$advanced_short")" \
FM_FAKE_NM_RUNS_LIST="$(cat <<EOF
$(ledger_row running fm/task-x1 "$advanced_short" 2026-09-03 07:55 http://pi4:3001/joergoss/Scan2Excel/pulls/7)
$(ledger_row failed fm/task-x1 "$anchor_short" 2026-09-02 06:36)
EOF
)" \
FM_FAKE_NM_ABORT_LOG="$case_dir/nm-abort.log" \
  run_teardown "$case_dir" > "$case_dir/stdout" 2> "$case_dir/stderr" || rc=$?
[ "$rc" -eq 0 ] || { cat "$case_dir/stderr"; fail "HTTP parked-run teardown failed"; }
grep -q 'abort --run 01RUN' "$case_dir/nm-abort.log" || fail "HTTP parked run was not aborted"
printf '$ bin/fm-teardown.sh task-x1 (newest running ledger row carries an HTTP Forgejo PR)\nexit: %s\n' "$rc"
printf 'validation command invoked: '; cat "$case_dir/nm-abort.log"
printf 'task result: '; grep -E 'parked at a gate|aborting' "$case_dir/stderr" | head -1
