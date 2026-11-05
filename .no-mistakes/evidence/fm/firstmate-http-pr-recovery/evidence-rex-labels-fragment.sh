# Product-level evidence for the public Rex mark planner.
mark_case evidence-http-labels
printf 'on\n' > "$MARK_DIR/home/config/rex-status-marks"
printf '%s\n' "window=$MARK_T" "backend=rex" "kind=ship" > "$MARK_DIR/home/state/t1.meta"
mark_task_status 'done [at=1700000350]: PR http://pi4:3001/o/r/pulls/9 merged'
ready=$(marks_run plan t1)
assert_contains "$ready" $'done\t\tPR ready: PR http://pi4:3001/o/r/pulls/9 merged' "HTTP ready label missing"
mark_task_status 'done [at=1700000375]: Published http://internal/docs'
ordinary=$(marks_run plan t1)
assert_contains "$ordinary" $'done\t\tDone: Published http://internal/docs' "ordinary HTTP link mislabeled"
mark_task_status 'done [at=1700000380]: Documented PR http://pi4:3001/o/r/pulls/7 in the handbook'
prose=$(marks_run plan t1)
assert_contains "$prose" $'done\t\tDone: Documented PR http://pi4:3001/o/r/pulls/7 in the handbook' "prose HTTP PR mislabeled"
printf '$ bin/fm-rex-marks.sh plan t1\nready report:\n%s\n\nunrelated HTTP link:\n%s\n\nHTTP PR mentioned in prose:\n%s\n' "$ready" "$ordinary" "$prose"
