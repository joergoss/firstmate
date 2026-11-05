# Product-level evidence for secondmate ledger-first PR recovery.
url=http://pi4:3001/o/r/pulls/7
make_world evidence-forgejo-ledger
bind_secondmate local
write_child "$MATE" child "done: PR $url checks green"
awk '!/^pr=/' "$MATE/state/child.meta" > "$MATE/state/child.meta.tmp" && mv "$MATE/state/child.meta.tmp" "$MATE/state/child.meta"
age "$MATE/state/child.meta"
FM_FAKE_CREW_STATE='unknown' run_reconcile "$MATE"
key=$(reported_outcome_key "$MATE" child 'done') || fail "ledger outcome was not reported"
report=$(sed -E 's/ \[at=[0-9]+\]//' "$MAIN/state/mate.status")
printf '%s\n' "$report" | grep -Fxq "done [key=$key]: child child done: PR $url checks green pr=$url mode=no-mistakes yolo=off" \
  || fail "parent report lost HTTP Forgejo PR"
printf '$ bin/fm-inactive-reconcile.sh <secondmate> (child meta has no pr=)\nparent report:\n%s\n' "$report"
