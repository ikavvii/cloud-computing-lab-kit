"""Validate real engine output, not a substitute implementation of the labs."""
from pathlib import Path
from decimal import Decimal
import re

root = Path('/workspace/artifacts')
weather = (root / 'weather-result.tsv').read_text().strip().splitlines()
assert weather == [
    '2024-01-01\t25.0\tShiny Day', '2024-01-02\t18.5\tCool Day',
    '2024-01-03\t30.0\tShiny Day', '2024-01-04\t-2.0\tCool Day',
    '2024-01-05\t24.99\tCool Day', '2024-01-06\t25.01\tShiny Day'], weather
edge = (root / 'weather-edge-result.tsv').read_text().strip().splitlines()
assert edge == ['2024-02-01\t28.0\tShiny Day', '2024-02-02\t25.0\tShiny Day',
                '2024-02-03\t-3.0\tCool Day'], edge
rows = [line.split('\t') for line in (root / 'pig-result.tsv').read_text().strip().splitlines()]
assert [r[0] for r in rows] == ['P002', 'P004', 'P006'], rows
assert Decimal(rows[0][4]) == 2 and rows[0][5] == '2', rows
assert rows[1][4:] == ['', '0'] and rows[2][4:] == ['', '0'], rows
expected = {
    '5001': ('500', '450', '1'), '5002': (None, None, '1'),
    '5003': ('1200.50', '1080.45', '2'), '5004': ('750.25', '675.23', '2'),
    '5005': (None, None, '3'), '5006': ('2100.75', '1890.68', '3'),
    '5007': ('850', '765', '4'), '5008': ('450.50', '405.45', '4')}
hive = [r.split('\t') for r in (root / 'hive-result.tsv').read_text().splitlines()]
assert len(hive) == 8 and len({r[0] for r in hive}) == 8, hive
for row in hive:
    amount, discount, month = expected[row[0]]
    assert row[3:] == ['2024', month], row
    if amount is None:
        assert row[1].upper() == 'NULL' and row[2].upper() == 'NULL', row
    else:
        assert Decimal(row[1]) == Decimal(amount) and Decimal(row[2]) == Decimal(discount), row
makespans = {}
for policy in ['minmin', 'roundrobin']:
    text = (root / f'cloudsim-{policy}.txt').read_text()
    results = [line.split(',') for line in text.splitlines() if re.match(r'^RESULT,\d', line)]
    assert len(results) == 6 and len({r[1] for r in results}) == 6, text
    assert all(float(r[5]) >= float(r[4]) for r in results), text
    match = re.search(r'completed=6,makespan=([0-9.]+)', text)
    assert match, text
    makespans[policy] = float(match.group(1))
    expected_bindings = [2, 1, 1, 2, 2, 2] if policy == 'minmin' else [0, 1, 2, 0, 1, 2]
    assert [int(r[2]) for r in results] == expected_bindings, results
assert all(value > 0 for value in makespans.values()), makespans
# This input actually favors round-robin: approximate ideal makespans 15 vs 16.
# A custom algorithm need not outperform another on every workload.
print('PASS: weather boundaries/invalid rows/daily maximum, Pig join/nulls/ratings, all 8 Hive results, both CloudSim runs.')
