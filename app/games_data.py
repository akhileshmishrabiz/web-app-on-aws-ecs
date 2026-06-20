"""Game content and validation logic for DevOps Games Platform."""

PIPELINE_STAGES = [
    {"id": "checkout", "label": "Checkout Code", "icon": "📥"},
    {"id": "lint", "label": "Lint & Format", "icon": "🔍"},
    {"id": "test", "label": "Run Tests", "icon": "🧪"},
    {"id": "build", "label": "Build Image", "icon": "🏗️"},
    {"id": "scan", "label": "Security Scan", "icon": "🛡️"},
    {"id": "deploy", "label": "Deploy to Prod", "icon": "🚀"},
]

PIPELINE_CORRECT_ORDER = ["checkout", "lint", "test", "build", "scan", "deploy"]

INCIDENT_SCENARIOS = [
    {
        "id": 1,
        "title": "502 Bad Gateway",
        "description": "Users report the site is down. ALB health checks are failing on 3/5 targets.",
        "time_limit": 15,
        "options": [
            {"id": "a", "text": "Scale down to zero and go home", "correct": False, "feedback": "That's... not how on-call works."},
            {"id": "b", "text": "Check target group health & recent deployments", "correct": True, "feedback": "Smart! Always correlate health checks with recent changes."},
            {"id": "c", "text": "Delete the load balancer", "correct": False, "feedback": "Please no. The LB is not the problem."},
            {"id": "d", "text": "Reboot your laptop", "correct": False, "feedback": "Your laptop is fine. The servers aren't."},
        ],
    },
    {
        "id": 2,
        "title": "Database Connection Pool Exhausted",
        "description": "App logs show 'FATAL: sorry, too many clients already'. Error rate at 45%.",
        "time_limit": 15,
        "options": [
            {"id": "a", "text": "Increase max_connections & investigate connection leaks", "correct": True, "feedback": "Good triage — fix the immediate issue, then find the leak."},
            {"id": "b", "text": "DROP DATABASE production", "correct": False, "feedback": "Absolutely not. Step away from the terminal."},
            {"id": "c", "text": "Add more RAM to the app servers", "correct": False, "feedback": "RAM won't fix a connection pool exhaustion."},
            {"id": "d", "text": "Post in #general 'is prod down?'", "correct": False, "feedback": "Use the incident channel and start investigating!"},
        ],
    },
    {
        "id": 3,
        "title": "Certificate Expired",
        "description": "Browser shows NET::ERR_CERT_DATE_INVALID. SSL cert expired 2 hours ago.",
        "time_limit": 12,
        "options": [
            {"id": "a", "text": "Tell users to click 'Advanced → Proceed'", "correct": False, "feedback": "Never ask users to bypass cert warnings in prod."},
            {"id": "b", "text": "Renew cert via ACM/Let's Encrypt & update ALB listener", "correct": True, "feedback": "Cert renewal is the fix. Set up auto-renewal alerts next time!"},
            {"id": "c", "text": "Switch to HTTP only", "correct": False, "feedback": "Downgrading to HTTP is a security incident, not a fix."},
            {"id": "d", "text": "Wait for it to fix itself", "correct": False, "feedback": "Certs don't self-heal. Renew it!"},
        ],
    },
    {
        "id": 4,
        "title": "Redis OOM",
        "description": "Cache layer returning errors. Redis logs: 'OOM command not allowed'.",
        "time_limit": 15,
        "options": [
            {"id": "a", "text": "Flush all keys immediately", "correct": False, "feedback": "Flushing might cause a thundering herd. Triage first."},
            {"id": "b", "text": "Evict stale keys, increase memory limit, check for key explosion", "correct": True, "feedback": "Proper cache triage — evict, scale, and find the root cause."},
            {"id": "c", "text": "Disable caching entirely", "correct": False, "feedback": "That'll melt your database. Fix Redis instead."},
            {"id": "d", "text": "Restart Redis every 5 minutes via cron", "correct": False, "feedback": "Cron restarts are a band-aid, not a strategy."},
        ],
    },
    {
        "id": 5,
        "title": "Disk Full on Primary Node",
        "description": "Monitoring alert: /var partition at 98%. Writes failing on primary DB node.",
        "time_limit": 15,
        "options": [
            {"id": "a", "text": "Truncate production tables to free space", "correct": False, "feedback": "Never truncate prod to fix disk space. Find what's filling the disk."},
            {"id": "b", "text": "Rotate logs, expand volume, identify runaway growth", "correct": True, "feedback": "Classic disk triage — free space now, expand capacity, find the leak."},
            {"id": "c", "text": "Reboot the server and hope for the best", "correct": False, "feedback": "A reboot won't shrink your logs or WAL files."},
            {"id": "d", "text": "Disable monitoring so alerts stop", "correct": False, "feedback": "Silencing alerts is not incident response."},
        ],
    },
    {
        "id": 6,
        "title": "DNS Propagation Failure",
        "description": "New service unreachable externally. Internal curl works. External users get NXDOMAIN.",
        "time_limit": 12,
        "options": [
            {"id": "a", "text": "Check Route53/Cloudflare records & TTL propagation", "correct": True, "feedback": "DNS issues start at the registrar — verify records and propagation."},
            {"id": "b", "text": "Redeploy the application", "correct": False, "feedback": "The app is fine internally. This is a DNS problem."},
            {"id": "c", "text": "Flush DNS on every user's machine", "correct": False, "feedback": "You can't flush DNS for the entire internet."},
            {"id": "d", "text": "Switch to IP addresses in the docs", "correct": False, "feedback": "Hardcoding IPs is fragile and won't scale."},
        ],
    },
]

DOCKERFILE_CHALLENGES = [
    {
        "id": 1,
        "title": "Missing WORKDIR",
        "broken": """FROM python:3.11-slim
COPY requirements.txt .
RUN pip install -r requirements.txt
COPY . .
CMD ["python", "app.py"]""",
        "fixed": """FROM python:3.11-slim
WORKDIR /app
COPY requirements.txt .
RUN pip install -r requirements.txt
COPY . .
CMD ["python", "app.py"]""",
        "hint": "Where does the app live inside the container?",
        "errors": ["Missing WORKDIR directive"],
    },
    {
        "id": 2,
        "title": "Wrong COPY Order",
        "broken": """FROM node:18-alpine
COPY . .
COPY package*.json ./
RUN npm ci --production
CMD ["node", "server.js"]""",
        "fixed": """FROM node:18-alpine
WORKDIR /app
COPY package*.json ./
RUN npm ci --production
COPY . .
CMD ["node", "server.js"]""",
        "hint": "Copy dependency files before source for better layer caching.",
        "errors": ["COPY . . before package.json breaks cache", "Missing WORKDIR"],
    },
    {
        "id": 3,
        "title": "Running as Root",
        "broken": """FROM python:3.11-slim
WORKDIR /app
COPY . .
RUN pip install -r requirements.txt
USER root
EXPOSE 8080
CMD ["gunicorn", "-b", "0.0.0.0:8080", "app:app"]""",
        "fixed": """FROM python:3.11-slim
WORKDIR /app
RUN useradd -m appuser
COPY . .
RUN pip install -r requirements.txt
USER appuser
EXPOSE 8080
CMD ["gunicorn", "-b", "0.0.0.0:8080", "app:app"]""",
        "hint": "Production containers shouldn't run as root.",
        "errors": ["Running as root (USER root)", "No non-root user created"],
    },
]

K8S_YAML_CHALLENGES = [
    {
        "id": 1,
        "title": "Wrong API Version",
        "broken": """apiVersion: extensions/v1beta1
kind: Deployment
metadata:
  name: web-app
spec:
  replicas: 3
  selector:
    matchLabels:
      app: web
  template:
    metadata:
      labels:
        app: web
    spec:
      containers:
      - name: web
        image: myapp:latest
        ports:
        - containerPort: 8080""",
        "fixed": """apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-app
spec:
  replicas: 3
  selector:
    matchLabels:
      app: web
  template:
    metadata:
      labels:
        app: web
    spec:
      containers:
      - name: web
        image: myapp:latest
        ports:
        - containerPort: 8080""",
        "hint": "extensions/v1beta1 was removed in K8s 1.22+",
        "errors": ["Deprecated apiVersion: extensions/v1beta1"],
    },
    {
        "id": 2,
        "title": "Missing Resource Limits",
        "broken": """apiVersion: v1
kind: Pod
metadata:
  name: api-pod
spec:
  containers:
  - name: api
    image: api:v2
    ports:
    - containerPort: 3000""",
        "fixed": """apiVersion: v1
kind: Pod
metadata:
  name: api-pod
spec:
  containers:
  - name: api
    image: api:v2
    ports:
    - containerPort: 3000
    resources:
      requests:
        memory: "128Mi"
        cpu: "100m"
      limits:
        memory: "256Mi"
        cpu: "500m" """,
        "hint": "Pods without limits can OOM the node.",
        "errors": ["Missing resources.requests", "Missing resources.limits"],
    },
    {
        "id": 3,
        "title": "Invalid Indentation",
        "broken": """apiVersion: v1
kind: Service
metadata:
  name: web-svc
spec:
  type: ClusterIP
  selector:
    app: web
ports:
  - port: 80
    targetPort: 8080""",
        "fixed": """apiVersion: v1
kind: Service
metadata:
  name: web-svc
spec:
  type: ClusterIP
  selector:
    app: web
  ports:
    - port: 80
      targetPort: 8080""",
        "hint": "YAML indentation matters — ports belongs under spec.",
        "errors": ["ports not indented under spec"],
    },
]

LOG_CHALLENGES = [
    {
        "id": 1,
        "title": "NullPointer in Payment Service",
        "logs": """2024-06-15T10:23:01Z INFO  [payment-svc] Processing payment order_id=8821 amount=49.99
2024-06-15T10:23:01Z DEBUG [payment-svc] Fetching user profile user_id=4412
2024-06-15T10:23:01Z DEBUG [payment-svc] User profile loaded successfully
2024-06-15T10:23:02Z ERROR [payment-svc] java.lang.NullPointerException: Cannot invoke "String.length()" because "cardToken" is null
2024-06-15T10:23:02Z ERROR [payment-svc]   at com.acme.payment.ChargeService.charge(ChargeService.java:87)
2024-06-15T10:23:02Z WARN  [payment-svc] Payment failed for order_id=8821, initiating rollback
2024-06-15T10:23:02Z INFO  [payment-svc] Rollback complete order_id=8821""",
        "error_line": 4,
        "error_summary": "NullPointerException: cardToken is null",
        "options": [
            "Database connection timeout",
            "NullPointerException: cardToken is null",
            "OutOfMemoryError in JVM heap",
            "SSL handshake failure",
        ],
        "correct_index": 1,
    },
    {
        "id": 2,
        "title": "Connection Refused to Redis",
        "logs": """2024-06-15T14:05:10Z INFO  [session-svc] Starting session lookup session_id=abc123
2024-06-15T14:05:10Z DEBUG [session-svc] Connecting to redis://cache.internal:6379
2024-06-15T14:05:15Z ERROR [session-svc] redis.exceptions.ConnectionError: Error 111 connecting to cache.internal:6379. Connection refused.
2024-06-15T14:05:15Z WARN  [session-svc] Falling back to database for session lookup
2024-06-15T14:05:16Z INFO  [session-svc] Session loaded from DB session_id=abc123 latency=1200ms""",
        "error_line": 3,
        "error_summary": "Connection refused to Redis on port 6379",
        "options": [
            "Connection refused to Redis on port 6379",
            "Invalid JSON in request body",
            "Pod evicted due to memory pressure",
            "DNS resolution failed for api.example.com",
        ],
        "correct_index": 0,
    },
    {
        "id": 3,
        "title": "OOM Kill in Worker Pod",
        "logs": """2024-06-15T08:00:00Z INFO  [worker-7] Processing batch job_id=9912 items=50000
2024-06-15T08:00:05Z INFO  [worker-7] Loaded 50000 records into memory
2024-06-15T08:00:12Z WARN  [worker-7] Memory usage at 92% (1.8Gi/2Gi)
2024-06-15T08:00:18Z ERROR [worker-7] Killed
2024-06-15T08:00:18Z ERROR [kubelet] Container worker-7 terminated: OOMKilled (exit code 137)
2024-06-15T08:00:19Z INFO  [kubelet] Restarting container worker-7 (restart count: 4)""",
        "error_line": 5,
        "error_summary": "Container OOMKilled (exit code 137)",
        "options": [
            "Container OOMKilled (exit code 137)",
            "ImagePullBackOff on registry",
            "Liveness probe failed HTTP 503",
            "ConfigMap key not found",
        ],
        "correct_index": 0,
    },
]

DEPLOY_SCENARIOS = [
    {
        "id": 1,
        "title": "Friday 4:58 PM Deploy",
        "context": "Your team wants to ship a 'tiny' config change before the weekend. Monitoring shows baseline traffic. No rollback tested.",
        "metrics": {"error_rate": "0.1%", "latency_p99": "120ms", "deploys_today": 0},
        "options": [
            {"id": "deploy", "text": "🚀 Deploy now — it's just a config change!", "correct": False, "points": 0, "feedback": "Friday deploys without rollback plans? Bold. Also wrong."},
            {"id": "rollback", "text": "🛑 Wait until Monday with a tested rollback plan", "correct": True, "points": 100, "feedback": "Zero Downtime Hero move! Ship Monday with confidence."},
            {"id": "canary", "text": "🐤 Canary deploy with 5% traffic & auto-rollback", "correct": True, "points": 80, "feedback": "Solid compromise — canary with auto-rollback is acceptable."},
            {"id": "yolo", "text": "🔥 Deploy AND delete staging to save costs", "correct": False, "points": -50, "feedback": "You monster. Never delete staging before a deploy."},
        ],
    },
    {
        "id": 2,
        "title": "Error Rate Spike Post-Deploy",
        "context": "You deployed v2.4.1 ten minutes ago. Error rate jumped from 0.2% to 8%. Latency is stable. Rollback takes ~3 minutes.",
        "metrics": {"error_rate": "8.0%", "latency_p99": "130ms", "deploys_today": 1},
        "options": [
            {"id": "wait", "text": "⏳ Wait 30 min — might be cache warming", "correct": False, "points": 0, "feedback": "8% error rate is not cache warming. Roll back!"},
            {"id": "rollback", "text": "⏪ Rollback immediately to v2.4.0", "correct": True, "points": 100, "feedback": "Correct! Roll back first, investigate later."},
            {"id": "scale", "text": "📈 Scale up replicas to 20", "correct": False, "points": 20, "feedback": "Scaling won't fix application errors. Roll back."},
            {"id": "deploy", "text": "🚀 Deploy v2.4.2 hotfix right now", "correct": False, "points": 0, "feedback": "Deploying on top of a broken deploy? Double trouble."},
        ],
    },
    {
        "id": 3,
        "title": "Database Migration in Progress",
        "context": "A long-running migration is 60% complete. Users see intermittent 500s. Rollback script exists but takes 15 minutes.",
        "metrics": {"error_rate": "3.5%", "latency_p99": "890ms", "deploys_today": 0},
        "options": [
            {"id": "abort", "text": "🛑 Abort migration & rollback schema", "correct": False, "points": 30, "feedback": "Aborting mid-migration can corrupt data. Assess first."},
            {"id": "continue", "text": "✅ Continue migration with read-only mode enabled", "correct": True, "points": 100, "feedback": "Smart! Enable read-only, finish migration, then restore writes."},
            {"id": "deploy", "text": "🚀 Deploy new app version to fix 500s", "correct": False, "points": 0, "feedback": "The 500s are from the migration, not the app version."},
            {"id": "ignore", "text": "😴 It's fine, migrations always cause blips", "correct": False, "points": -20, "feedback": "3.5% errors aren't blips. Take action."},
        ],
    },
    {
        "id": 4,
        "title": "All Green on Dashboard",
        "context": "All metrics green. A critical security patch (CVE-2024-9999) was released. Patch requires restart. Current uptime: 847 days.",
        "metrics": {"error_rate": "0.0%", "latency_p99": "95ms", "deploys_today": 0},
        "options": [
            {"id": "never", "text": "🏆 Keep the uptime streak! Patch never.", "correct": False, "points": -100, "feedback": "847 days of uptime, 1 day of breach headlines."},
            {"id": "deploy", "text": "🔒 Schedule rolling restart with security patch", "correct": True, "points": 100, "feedback": "Security patches don't wait for uptime trophies."},
            {"id": "rollback", "text": "⏪ Rollback to previous version", "correct": False, "points": 0, "feedback": "Rollback removes the patch. You need to apply it!"},
            {"id": "firewall", "text": "🧱 Block all inbound traffic instead", "correct": False, "points": -50, "feedback": "That's called 'taking prod offline'. Patch it."},
        ],
    },
]

ACHIEVEMENTS = {
    "pipeline_master": {
        "name": "Pipeline Master",
        "icon": "🔧",
        "description": "Perfect Pipeline Puzzle score",
        "game": "pipeline_puzzle",
        "threshold": 600,
        "threshold_label": "600 XP",
    },
    "zero_downtime_hero": {
        "name": "Zero Downtime Hero",
        "icon": "🦸",
        "description": "Score 300+ in Deploy or Rollback",
        "game": "deploy_rollback",
        "threshold": 300,
        "threshold_label": "300 XP",
    },
    "log_sleuth": {
        "name": "Log Sleuth",
        "icon": "🔎",
        "description": "Perfect Log Detective run",
        "game": "log_detective",
        "threshold": 450,
        "threshold_label": "450 XP",
    },
    "incident_warlord": {
        "name": "Incident Warlord",
        "icon": "⚔️",
        "description": "Score 350+ in Incident Commander",
        "game": "incident_commander",
        "threshold": 350,
        "threshold_label": "350 XP",
    },
    "docker_whisperer": {
        "name": "Docker Whisperer",
        "icon": "🐳",
        "description": "Fix all Dockerfile challenges",
        "game": "dockerfile_builder",
        "threshold": 450,
        "threshold_label": "450 XP",
    },
    "yaml_yoda": {
        "name": "YAML Yoda",
        "icon": "🧙",
        "description": "Fix all K8s YAML challenges",
        "game": "k8s_yaml_fixer",
        "threshold": 450,
        "threshold_label": "450 XP",
    },
    "devops_legend": {
        "name": "DevOps Legend",
        "icon": "👑",
        "description": "Play all six games",
        "game": "all",
        "threshold": 6,
        "threshold_label": "6 games",
    },
}

SLUG_TO_GAME_TYPE = {
    "pipeline-puzzle": "pipeline_puzzle",
    "incident-commander": "incident_commander",
    "dockerfile-builder": "dockerfile_builder",
    "k8s-yaml-fixer": "k8s_yaml_fixer",
    "log-detective": "log_detective",
    "deploy-rollback": "deploy_rollback",
}

GAME_TYPE_LABELS = {
    "pipeline_puzzle": "Pipeline Puzzle",
    "incident_commander": "Incident Commander",
    "dockerfile_builder": "Dockerfile Builder",
    "k8s_yaml_fixer": "K8s YAML Fixer",
    "log_detective": "Log Detective",
    "deploy_rollback": "Deploy or Rollback",
}

GAMES = [
    {
        "slug": "pipeline-puzzle",
        "name": "Pipeline Puzzle",
        "icon": "🔧",
        "description": "Drag CI/CD stages into the correct order before the build breaks.",
        "color": "#6366f1",
        "difficulty": "Easy",
        "tags": ["CI/CD", "Drag & Drop"],
        "xp_max": 600,
    },
    {
        "slug": "incident-commander",
        "name": "Incident Commander",
        "icon": "🚨",
        "description": "You're on-call. Pick the right response before the pager explodes.",
        "color": "#ef4444",
        "difficulty": "Medium",
        "tags": ["On-Call", "Timed"],
        "xp_max": 500,
    },
    {
        "slug": "dockerfile-builder",
        "name": "Dockerfile Builder",
        "icon": "🐳",
        "description": "Fix broken Dockerfiles before they hit production.",
        "color": "#0ea5e9",
        "difficulty": "Medium",
        "tags": ["Containers", "Security"],
        "xp_max": 450,
    },
    {
        "slug": "k8s-yaml-fixer",
        "name": "K8s YAML Fixer",
        "icon": "☸️",
        "description": "Spot and fix Kubernetes manifest errors.",
        "color": "#8b5cf6",
        "difficulty": "Hard",
        "tags": ["Kubernetes", "YAML"],
        "xp_max": 450,
    },
    {
        "slug": "log-detective",
        "name": "Log Detective",
        "icon": "🔎",
        "description": "Find the needle of error in the haystack of logs.",
        "color": "#f59e0b",
        "difficulty": "Medium",
        "tags": ["Debugging", "Logs"],
        "xp_max": 450,
    },
    {
        "slug": "deploy-rollback",
        "name": "Deploy or Rollback",
        "icon": "🎲",
        "description": "High-pressure deploy decisions. Ship it or roll it back?",
        "color": "#10b981",
        "difficulty": "Hard",
        "tags": ["Deploy", "Strategy"],
        "xp_max": 400,
    },
]
