from fastapi import APIRouter, WebSocket, WebSocketDisconnect
import json
import asyncio

router = APIRouter()

@router.websocket("/chat/{user_id}")
async def websocket_endpoint(websocket: WebSocket, user_id: int):
    await websocket.accept()
    
    try:
        while True:
            try:
                data = await websocket.receive_text()
                user_msg = json.loads(data)
                
                question = user_msg.get("content", "").strip()
                session_id = user_msg.get("session_id", f"session_{user_id}_{asyncio.get_event_loop().time()}")
                files = user_msg.get("files", [])
                
                if not question:
                    await websocket.send_json({
                        "role": "ai",
                        "content": "请输入您的问题",
                        "is_end": True
                    })
                    continue
                
                response_text = "您好！我是农业智能问答助手。目前系统正在测试中，暂时无法提供具体的农业诊断服务。请稍后再试。"
                
                for char in response_text:
                    await websocket.send_json({
                        "role": "ai",
                        "content": char,
                        "is_end": False
                    })
                    await asyncio.sleep(0.05)
                
                await websocket.send_json({
                    "role": "ai",
                    "content": "",
                    "is_end": True
                })
                
            except json.JSONDecodeError:
                await websocket.send_json({
                    "role": "ai",
                    "content": "消息格式错误，请检查输入",
                    "is_end": True
                })
            except Exception as e:
                await websocket.send_json({
                    "role": "ai",
                    "content": f"服务错误: {str(e)}",
                    "is_end": True
                })
                
    except WebSocketDisconnect:
        print(f"用户 {user_id} 已断开连接")
    except Exception as e:
        print(f"WebSocket 连接异常: {e}")
