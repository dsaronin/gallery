#!/usr/bin/env bash
# ----------------------------------------------------------
# Gallery: Run all test scripts in script/
# ----------------------------------------------------------

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

cd "${PROJECT_ROOT}" || exit 1

passed=0
failed=0
failures=()

echo "=========================================================="
echo " Running all test scripts in script/"
echo "=========================================================="

for test_file in script/test_*.rb; do
  [ -e "$test_file" ] || continue

  echo ""
  echo "--> Running: ${test_file}"
  echo "----------------------------------------------------------"

  if bin/rails runner "${test_file}"; then
    echo "--> [PASS] ${test_file}"
    ((passed++))
  else
    echo "--> [FAIL] ${test_file}"
    ((failed++))
    failures+=("${test_file}")
  fi
done

echo ""
echo "=========================================================="
echo " Test Suite Summary"
echo "=========================================================="
echo "Total:  $((passed + failed))"
echo "Passed: ${passed}"
echo "Failed: ${failed}"

if [ "${failed}" -gt 0 ]; then
  echo ""
  echo "Failed scripts:"
  for f in "${failures[@]}"; do
    echo "  - ${f}"
  done
  echo "=========================================================="
  exit 1
else
  echo ""
  echo "All test scripts completed successfully."
  echo "=========================================================="
  exit 0
fi


