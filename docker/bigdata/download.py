"""Bounded parallel HTTP range downloader for large official release archives.

The caller verifies the final archive's published checksum/signature. Chunks live
in a BuildKit cache so an interrupted build can resume instead of starting over.
"""
import concurrent.futures
import hashlib
import os
from pathlib import Path
import shutil
import sys
import time
import urllib.request

url, destination = sys.argv[1:]
cache = Path('/var/cache/lab-downloads') / hashlib.sha256(url.encode()).hexdigest()
cache.mkdir(parents=True, exist_ok=True)
request = urllib.request.Request(url, headers={'Range': 'bytes=0-0'})
with urllib.request.urlopen(request, timeout=90) as response:
    header = response.headers.get('Content-Range', '')
    if response.status != 206 or not header.startswith('bytes 0-0/'):
        raise RuntimeError('Server must support byte ranges for resumable downloads')
    total = int(header.rsplit('/', 1)[1])
    response.read(1)
chunk_size = 8 * 1024 * 1024
count = (total + chunk_size - 1) // chunk_size

def fetch(index):
    start = index * chunk_size
    end = min(total - 1, start + chunk_size - 1)
    length = end - start + 1
    target = cache / f'{index:05d}.chunk'
    if target.exists() and target.stat().st_size == length:
        print(f'Cached chunk {index + 1}/{count}', flush=True)
        return
    partial = target.with_suffix('.partial')
    for attempt in range(5):
        try:
            req = urllib.request.Request(url, headers={'Range': f'bytes={start}-{end}'})
            with urllib.request.urlopen(req, timeout=90) as response, partial.open('wb') as out:
                if response.status != 206 or response.headers.get('Content-Range') != f'bytes {start}-{end}/{total}':
                    raise RuntimeError('Unexpected range response')
                received = 0
                while received < length:
                    data = response.read(min(1024 * 1024, length - received))
                    if not data:
                        break
                    out.write(data)
                    received += len(data)
                if received != length:
                    raise RuntimeError(f'Short chunk: {received}/{length}')
            os.replace(partial, target)
            print(f'Downloaded chunk {index + 1}/{count}', flush=True)
            return
        except Exception:
            if attempt == 4:
                raise
            time.sleep(min(2 ** attempt, 10))

with concurrent.futures.ThreadPoolExecutor(max_workers=8) as pool:
    list(pool.map(fetch, range(count)))
with open(destination, 'wb') as out:
    for index in range(count):
        with (cache / f'{index:05d}.chunk').open('rb') as part:
            shutil.copyfileobj(part, out, 1024 * 1024)
print(f'Assembled {total} bytes; archive verification follows.', flush=True)
