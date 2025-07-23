# pwndbg-MCP_for_Docker

# pwndbg MCP 서버 🐛

AI(Claude)와 pwndbg를 연결하여 바이너리 분석 및 디버깅을 자동화하는 MCP(Model Context Protocol) 서버입니다.

## 🎯 개요

```
Claude AI → docker exec → [Container: MCP Server → pwndbg → GDB] → Target Binary
```

Claude가 Docker 컨테이너 내의 pwndbg와 직접 통신하여 힙 분석, 보안 검사, 메모리 덤프 등을 수행할 수 있습니다.

## ⚡ 주요 기능

- **힙 분석**: heap, bins, chunks, tcache 분석
- **보안 검사**: checksec, canary, vmmap 확인  
- **메모리 분석**: stack, registers, telescope로 메모리 덤프
- **검색 기능**: 패턴 검색, GOT/PLT 테이블 확인
- **안전한 실행**: 화이트리스트 기반 명령어 필터링

## 🐳 설치 방법

### 1. Docker 환경 구성

**기본 pwndbg Docker 이미지 생성**
필요한 우분투 버전에 맞게 이미지를 빌드해주세요.

예시 이미지는 우분투 22.04로 만들었습니다.

**이미 컨테이너를 만들어둔 상태에서 MCP서버를 이식하고 싶다면
[2. MCP 서버 설치]로 넘어가시면 됩니다**

```dockerfile
# Dockerfile
FROM ubuntu:22.04

# 기본 패키지 설치
RUN apt-get update && apt-get install -y \
    gdb \
    python3 \
    python3-pip \
    git \
    wget \
    curl \
    && rm -rf /var/lib/apt/lists/*

# pwndbg 설치
RUN git clone https://github.com/pwndbg/pwndbg.git && \
    cd pwndbg && \
    ./setup.sh

# Python 의존성 설치
RUN pip3 install fastmcp

# 작업 디렉토리 생성
RUN mkdir -p /app /workspace

WORKDIR /app
```

**Docker 이미지 빌드 및 컨테이너 생성**

```bash
# 이미지 빌드
docker build -t pwndbg-mcp .

# 컨테이너 생성 및 실행
docker run -d --name pwndbg-container -it pwndbg-mcp /bin/bash
```



### 2. MCP 서버 설치

**서버 파일을 컨테이너에 복사**

```bash
# server.py를 컨테이너 내 /app 디렉토리로 복사
docker cp server.py pwndbg-container:/app/server.py

# 실행 권한 부여
docker exec pwndbg-container chmod +x /app/server.py
```

**분석할 바이너리 파일 복사 (선택사항)**

```bash
# 바이너리 파일들을 컨테이너로 복사
docker cp ./binaries/ pwndbg-container:/workspace/
```

### 3. Claude Desktop 설정

**config.json 파일 수정**

Claude Desktop 설정 파일을 찾아서 수정합니다:

- **Windows**: `%APPDATA%\Claude\claude_desktop_config.json`
- **macOS**: `~/Library/Application Support/Claude/claude_desktop_config.json`  
- **Linux**: `~/.config/Claude/claude_desktop_config.json`

```json
{
  "mcpServers": {
    "pwndbg-mcp": {
      "command": "docker",
      "args": [
        "exec",
        "-i", 
        "container-NAME",
        "python3", "/app/server.py"
      ],
      "env": {
        "PYTHONPATH": "/app",
        "GDB_BATCH": "1"
      }
    }
  }
}
```

### 4. 설치 확인

1. **컨테이너 실행 상태 확인**
```bash
docker ps | grep pwndbg-container
```

2. **Claude Desktop 재시작**

3. **Claude에서 테스트**
```
Claude에서: "pwndbg 연결 상태를 확인해주세요"
```

## 🛠️ 사용 가능한 도구들

### 힙 분석 도구
- `heap()`: 힙 상태 전체 요약
- `bins()`: 모든 bin 상태 확인
- `vis()`: 힙 청크 시각화
- `malloc_chunk(address)`: 특정 청크 분석

### 보안 분석 도구  
- `checksec()`: 바이너리 보안 기능 확인
- `vmmap()`: 메모리 매핑 정보
- `canary()`: 스택 카나리 확인

### 메모리/레지스터 도구
- `regs()`: 레지스터 상태 확인
- `stack()`: 스택 내용 확인
- `telescope(address)`: 메모리 덤프 (포인터 추적)
- `context()`: 전체 컨텍스트 확인

### 검색/분석 도구
- `search(pattern)`: 메모리 값 검색
- `find(pattern)`: 패턴 검색  
- `got()`: GOT 테이블 확인
- `plt()`: PLT 테이블 확인
- `rop()`: ROP 가젯 검색

### 고급 도구
- `execute_custom_command(command)`: 사용자 정의 명령어 실행
- `list_available_commands()`: 사용 가능한 모든 명령어 목록

## 📝 사용 예시

### 기본 분석 워크플로우

1. **디버깅 세션 시작**
```
Claude: "바이너리 /workspace/target을 로드해서 디버깅 세션을 시작해주세요"
→ start_debug_session("/workspace/target")
```

2. **보안 기능 확인**
```
Claude: "바이너리의 보안 기능을 확인해주세요"  
→ checksec()
```

3. **메모리 매핑 확인**
```
Claude: "메모리 레이아웃을 보여주세요"
→ vmmap()
```

4. **힙 상태 분석**
```
Claude: "현재 힙 상태를 분석해주세요"
→ heap()
→ bins()
```

### 고급 분석

```
Claude: "RIP 레지스터 주변 메모리를 덤프해주세요"
→ telescope("$rip")

Claude: "/bin/sh 문자열을 찾아주세요"  
→ search("/bin/sh")

Claude: "사용 가능한 ROP 가젯을 찾아주세요"
→ rop()
```



### 디버깅 팁

- `list_available_commands()`로 사용 가능한 명령어 확인
- `check_pwndbg_connection()`으로 연결 상태 점검
- Docker 로그 확인: `docker logs pwndbg-container`

## ⚠️ 보안 고려사항

- 화이트리스트 기반 명령어 필터링으로 악성 명령 차단
- Docker 컨테이너로 격리된 환경에서 실행
- 위험한 시스템 명령어 실행 제한
- 명령어 길이 및 패턴 검증


## 수정 예정
바이너리 로드 후 첫 도구 호출에는 pwndbg 초기화 메세지가 출력되며 AI가 확인하지 못 하고 다시 호출합니다.

초기화 메세지를 정리하는 방법을 찾아 수정하도록 하겠습니다.

<img width="935" height="637" alt="image" src="https://github.com/user-attachments/assets/5ab8591c-9b59-4628-9add-566b380631c2" />

