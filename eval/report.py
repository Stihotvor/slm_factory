#!/usr/bin/env python3
"""Compare eval iterations. Reads eval/results/*/scores.json (or a subdir list) and prints:
  - table of all runs sorted by timestamp
  - best-so-far per metric
  - optional: diff between two runs (--compare DIR_A DIR_B)

Usage:
  python3 eval/report.py                       # summary of every run
  python3 eval/report.py --last 5              # last 5 runs
  python3 eval/report.py --compare A B         # detailed task-level diff
"""
import argparse, json, glob, os

def load_all():
    rows = []
    for p in sorted(glob.glob("eval/results/*/scores.json")):
        s = json.load(open(p))
        s["_dir"] = os.path.dirname(p)
        rows.append(s)
    rows.sort(key=lambda r: r.get("timestamp", ""))
    return rows

def fmt(v):
    if v is None:
        return "—"
    return f"{v}"

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--last", type=int, default=0)
    ap.add_argument("--compare", nargs=2, metavar=("DIR_A", "DIR_B"))
    args = ap.parse_args()

    if args.compare:
        a = json.load(open(os.path.join(args.compare[0], "scores.json")))
        b = json.load(open(os.path.join(args.compare[1], "scores.json")))
        print(f"{'task':28} {'A':8} {'B':8}")
        bm = {t["id"]: t for t in b["per_task"]}
        for t in a["per_task"]:
            tb = bm.get(t["id"], {})
            print(f"{t['id']:28} {t['status']:8} {tb.get('status','—'):8}"
                  + ("   ← regressed" if t["status"] == "pass" and tb.get("status") == "fail" else "")
                  + ("   ← fixed" if t["status"] == "fail" and tb.get("status") == "pass" else ""))
        for k in ("success_rate", "t1_rate", "t2_rate", "t3_avg", "total_permission_violations",
                  "median_steps", "median_wall_s"):
            va, vb = a.get(k), b.get(k)
            arrow = ""
            if isinstance(va, (int, float)) and isinstance(vb, (int, float)) and va != vb:
                arrow = "↑" if vb > va else "↓"
            print(f"{k:28} {fmt(va):8} {fmt(vb):8} {arrow}")
        return

    rows = load_all()
    if args.last:
        rows = rows[-args.last:]
    if not rows:
        print("no runs yet — run eval/run_suite.sh first")
        return

    hdr = f"{'timestamp':20} {'label':24} {'model':34} {'succ':6} {'T1':6} {'T2':6} {'T3':6} {'viol':5} {'steps':6} {'wall':6}"
    print(hdr); print("-" * len(hdr))
    for s in rows:
        print(f"{s.get('timestamp','?'):20} {s.get('label','?')[:24]:24} {s.get('model','(agent pin)')[:34]:34} "
              f"{fmt(s.get('success_rate')):6} {fmt(s.get('t1_rate')):6} {fmt(s.get('t2_rate')):6} "
              f"{fmt(s.get('t3_avg')):6} {fmt(s.get('total_permission_violations')):5} "
              f"{fmt(s.get('median_steps')):6} {fmt(s.get('median_wall_s')):6}")

    best = max(rows, key=lambda r: r.get("success_rate") or 0)
    print(f"\nbest so far: {best['label']} success_rate={best.get('success_rate')} ({best['_dir']})")

if __name__ == "__main__":
    main()
