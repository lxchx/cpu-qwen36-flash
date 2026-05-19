import base64
import json
import struct
import time
import urllib.request
import zlib


def png_rgb(width: int, height: int) -> bytes:
    rows = []
    for y in range(height):
        row = bytearray([0])
        for x in range(width):
            row += bytes([0, 70, 255]) if 18 <= x < 78 and 18 <= y < 78 else bytes([240, 30, 30])
        rows.append(bytes(row))
    raw = b"".join(rows)

    def chunk(kind: bytes, data: bytes) -> bytes:
        return (
            struct.pack(">I", len(data))
            + kind
            + data
            + struct.pack(">I", zlib.crc32(kind + data) & 0xFFFFFFFF)
        )

    return (
        b"\x89PNG\r\n\x1a\n"
        + chunk(b"IHDR", struct.pack(">IIBBBBB", width, height, 8, 2, 0, 0, 0))
        + chunk(b"IDAT", zlib.compress(raw, 9))
        + chunk(b"IEND", b"")
    )


port = 8080
data_url = "data:image/png;base64," + base64.b64encode(png_rgb(96, 96)).decode()
payload = {
    "model": "local",
    "temperature": 0,
    "max_tokens": 128,
    "stream": False,
    "messages": [
        {
            "role": "user",
            "content": [
                {"type": "text", "text": "请只用一句中文回答：图片背景是什么颜色，中间方块是什么颜色？"},
                {"type": "image_url", "image_url": {"url": data_url}},
            ],
        }
    ],
}

req = urllib.request.Request(
    f"http://127.0.0.1:{port}/v1/chat/completions",
    data=json.dumps(payload).encode(),
    headers={"Content-Type": "application/json", "Authorization": "Bearer sk-local"},
)
t0 = time.time()
with urllib.request.urlopen(req, timeout=1200) as response:
    obj = json.loads(response.read().decode())

print(
    json.dumps(
        {
            "wall_ms": round((time.time() - t0) * 1000),
            "usage": obj.get("usage"),
            "timings": obj.get("timings"),
            "message": obj.get("choices", [{}])[0].get("message", {}),
        },
        ensure_ascii=False,
        indent=2,
    )
)
