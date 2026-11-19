#!/bin/bash
# src/ の md（jupytext 形式）を ipynb に変換し、上から順に実行して確かめる。
# 使い方: tools/build.sh [src/... .md ...]   （引数なしなら src/ の下を全部）
# 実行に使う Python は環境変数 NBPY（jupytext・nbclient などが入った venv の python）。
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PY="${NBPY:-python3}"
cd "$ROOT"
if [ $# -eq 0 ]; then set -- $(find src -name '*.md' | sort); fi
fail=0
for md in "$@"; do
  out="${md#src/}"; out="${out%.md}.ipynb"
  mkdir -p "$(dirname "$out")"
  "$PY" -m jupytext --quiet --to ipynb --output "$out" "$md"
  # 実行して確かめる（保存する ipynb には出力を入れない）
  if "$PY" -m jupyter nbconvert --to notebook --execute --ExecutePreprocessor.timeout=300 --stdout "$out" > /dev/null 2> /tmp/nbbuild_err.txt; then
    echo "OK   $out"
  else
    echo "FAIL $out"; tail -20 /tmp/nbbuild_err.txt; fail=1
  fi
done
# 各教材のページとトップの表を作り直す
"$PY" "$ROOT/tools/make_pages.py"
exit $fail
