#!/usr/bin/env python3
"""blender_clean.py — 批次测试前清理共享 Blender 场景中的历史 Agent 对象。

背景：多轮公平测试共用同一个 Blender 实例(localhost:9876, GUI 模式)。上一轮各 Agent
在场景里留下的 `${AGENT}_` 前缀对象(CLAUDE_/CODEX_/DSH_/DEVIN_/OPENCODE_)会残留到下一轮，
可能被新 Agent 误读/误用，造成"旧模型设计影响当前任务"的污染。

本工具连接 BlenderMCP addon 的 socket，只清理这五个 Agent 前缀的对象/材质/网格，
保留 Blender 默认场景(Cube/Camera/Light 等)。

安全设计：
  - 默认 DRY-RUN：只列出将被删除的对象，不实际删除。
  - --force 才真正删除。
  - 只删前缀匹配对象，绝不碰默认对象；操作前打印将被删清单供确认。
  - 通过 addon 的 execute_code 在 GUI 主线程执行，遵守 addon v1.2(禁止 --background)。

用法：
  python3 _harness-backup/orchestration/blender_clean.py            # 预览
  python3 _harness-backup/orchestration/blender_clean.py --force     # 实际清理
"""
import sys
import json
import socket

HOST = "127.0.0.1"
PORT = 9876
BUFFER = 1 << 20
RETRIES = 4
PREFIXES = ("CLAUDE_", "CODEX_", "DSH_", "DEVIN_", "OPENCODE_")

FORCE = "--force" in sys.argv


def recv_full(sock):
    sock.settimeout(60.0)
    chunks = []
    while True:
        try:
            chunk = sock.recv(BUFFER)
            if not chunk:
                break
            chunks.append(chunk)
            data = b"".join(chunks)
            try:
                json.loads(data.decode("utf-8"))
                return data
            except json.JSONDecodeError:
                continue
        except socket.timeout:
            break
    if chunks:
        return b"".join(chunks)
    raise RuntimeError("no data received from Blender")


def send_command(cmd_type, params=None):
    """Raw JSON request per BlenderMCP addon framing (validated protocol)."""
    cmd = {"type": cmd_type, "params": params or {}}
    last = None
    for attempt in range(RETRIES):
        try:
            with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
                s.connect((HOST, PORT))
                s.sendall(json.dumps(cmd).encode("utf-8"))
                data = recv_full(s)
            resp = json.loads(data.decode("utf-8"))
            if resp.get("status") == "error":
                raise RuntimeError("Blender error: %s" % resp.get("message"))
            return resp.get("result", {})
        except Exception as e:  # noqa: BLE001 - retry transient failures
            last = e
    raise RuntimeError("send failed after retries: %s" % last)


def main():
    print(f"[blender_clean] 连接 {HOST}:{PORT} (mode={'FORCE' if FORCE else 'DRY-RUN'})")
    print(f"[blender_clean] 清理前缀: {', '.join(PREFIXES)}")

    # 1. 列出当前场景对象
    scene = send_command("get_scene_info")
    objs = scene.get("objects", [])
    names = [o.get("name", "") for o in objs]
    matched = [n for n in names if n.startswith(PREFIXES)]
    print(f"[blender_clean] 场景对象总数: {scene.get('object_count', len(names))}")
    print(f"[blender_clean] 命中 Agent 前缀对象: {len(matched)}")
    for n in sorted(matched)[:40]:
        print(f"    - {n}")

    if not FORCE:
        print("[blender_clean] DRY-RUN: 未删除。加 --force 实际清理。")
        return 0

    if not matched:
        print("[blender_clean] 无 Agent 前缀对象，无需清理。")
        return 0

    # 2. 执行清理（只删前缀对象；材质/网格一并清理）
    code = """
import bpy
prefixes = %r
removed = []
for o in list(bpy.data.objects):
    if o.name.startswith(prefixes):
        removed.append(o.name)
        bpy.data.objects.remove(o, do_unlink=True)
for mat in list(bpy.data.materials):
    if mat.name.startswith(prefixes):
        bpy.data.materials.remove(mat)
for mesh in list(bpy.data.meshes):
    if mesh.name.startswith(prefixes):
        bpy.data.meshes.remove(mesh)
print("REMOVED_OBJECTS:", sorted(removed))
print("REMAINING_COUNT:", len(bpy.data.objects))
""" % (PREFIXES,)
    result = send_command("execute_code", {"code": code})
    print("[blender_clean] 执行结果:", json.dumps(result, ensure_ascii=False)[:600])
    print("[blender_clean] 完成。")
    return 0


if __name__ == "__main__":
    sys.exit(main())
