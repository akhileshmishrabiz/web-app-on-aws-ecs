import hashlib
import json
import os
import random
import time
from datetime import date, datetime

from celery import Celery
from flask import (
    Flask,
    flash,
    jsonify,
    redirect,
    render_template,
    request,
    session,
    url_for,
)
from flask_mail import Mail, Message
from sqlalchemy import desc, func

from config import Config
from games_data import (
    ACHIEVEMENTS,
    DEPLOY_SCENARIOS,
    DOCKERFILE_CHALLENGES,
    GAME_TYPE_LABELS,
    GAMES,
    INCIDENT_SCENARIOS,
    K8S_YAML_CHALLENGES,
    LOG_CHALLENGES,
    PIPELINE_CORRECT_ORDER,
    PIPELINE_STAGES,
    SLUG_TO_GAME_TYPE,
)
from models import GameScore, PlayerAchievement, PlayerProfile, db

app = Flask(__name__)
app.config.from_object(Config)
db.init_app(app)

_tables_ready = False


@app.before_request
def ensure_tables():
    global _tables_ready
    if not _tables_ready:
        db.create_all()
        _tables_ready = True


def get_player_name():
    return session.get("player_name", "Anonymous DevOps Hero")


def ensure_player(name):
    profile = PlayerProfile.query.filter_by(player_name=name).first()
    if not profile:
        profile = PlayerProfile(player_name=name)
        db.session.add(profile)
        db.session.commit()
    return profile


def award_badge(player_name, badge_id):
    if badge_id not in ACHIEVEMENTS:
        return False
    existing = PlayerAchievement.query.filter_by(
        player_name=player_name, badge_id=badge_id
    ).first()
    if existing:
        return False
    db.session.add(PlayerAchievement(player_name=player_name, badge_id=badge_id))
    db.session.commit()
    return True


def get_daily_game():
    seed = int(hashlib.md5(date.today().isoformat().encode()).hexdigest(), 16)
    return GAMES[seed % len(GAMES)]


def get_personal_bests(player_name):
    bests = {}
    for slug, game_type in SLUG_TO_GAME_TYPE.items():
        best = (
            db.session.query(func.max(GameScore.score))
            .filter_by(player_name=player_name, game_type=game_type)
            .scalar()
        )
        bests[slug] = best
    return bests


def get_badge_progress(player_name):
    earned_ids = {
        a.badge_id
        for a in PlayerAchievement.query.filter_by(player_name=player_name).all()
    }
    played_games = {
        row.game_type
        for row in GameScore.query.filter_by(player_name=player_name).all()
    }
    best_scores = {}
    for game_type in SLUG_TO_GAME_TYPE.values():
        best = (
            db.session.query(func.max(GameScore.score))
            .filter_by(player_name=player_name, game_type=game_type)
            .scalar()
        )
        if best is not None:
            best_scores[game_type] = best

    progress = {}
    for badge_id, badge in ACHIEVEMENTS.items():
        if badge_id in earned_ids:
            progress[badge_id] = {"earned": True, "current": badge["threshold"], "percent": 100}
            continue
        if badge["game"] == "all":
            current = len(played_games)
            threshold = badge["threshold"]
        else:
            current = best_scores.get(badge["game"], 0)
            threshold = badge["threshold"]
        percent = min(100, int((current / threshold) * 100)) if threshold else 0
        progress[badge_id] = {"earned": False, "current": current, "percent": percent}
    return progress


@app.errorhandler(404)
def not_found(e):
    return render_template("404.html", player=get_player_name()), 404


def check_achievements(player_name, game_type, score):
    earned = []
    if game_type == "pipeline_puzzle" and score >= 600:
        if award_badge(player_name, "pipeline_master"):
            earned.append("pipeline_master")
    if game_type == "deploy_rollback" and score >= 300:
        if award_badge(player_name, "zero_downtime_hero"):
            earned.append("zero_downtime_hero")
    if game_type == "log_detective" and score >= 450:
        if award_badge(player_name, "log_sleuth"):
            earned.append("log_sleuth")
    if game_type == "incident_commander" and score >= 350:
        if award_badge(player_name, "incident_warlord"):
            earned.append("incident_warlord")
    if game_type == "dockerfile_builder" and score >= 450:
        if award_badge(player_name, "docker_whisperer"):
            earned.append("docker_whisperer")
    if game_type == "k8s_yaml_fixer" and score >= 450:
        if award_badge(player_name, "yaml_yoda"):
            earned.append("yaml_yoda")

    played_games = {
        row.game_type
        for row in GameScore.query.filter_by(player_name=player_name).all()
    }
    if len(played_games) >= 6:
        if award_badge(player_name, "devops_legend"):
            earned.append("devops_legend")
    return earned


@app.route("/health")
def health():
    return jsonify({"status": "healthy", "service": "devops-games"}), 200


@app.route("/")
def home():
    player = get_player_name()
    profile = PlayerProfile.query.filter_by(player_name=player).first()
    badges = PlayerAchievement.query.filter_by(player_name=player).all()
    top_scores = (
        db.session.query(
            GameScore.player_name,
            func.sum(GameScore.score).label("total"),
        )
        .group_by(GameScore.player_name)
        .order_by(desc("total"))
        .limit(5)
        .all()
    )
    recent_scores = (
        GameScore.query.order_by(desc(GameScore.played_at)).limit(8).all()
    )
    daily_game = get_daily_game()
    personal_bests = get_personal_bests(player)
    return render_template(
        "home.html",
        games=GAMES,
        player=player,
        profile=profile,
        badges=badges,
        top_scores=top_scores,
        achievements=ACHIEVEMENTS,
        recent_scores=recent_scores,
        daily_game=daily_game,
        personal_bests=personal_bests,
        game_type_labels=GAME_TYPE_LABELS,
    )


@app.route("/set-player", methods=["POST"])
def set_player():
    name = request.form.get("player_name", "").strip()[:80]
    if name:
        session["player_name"] = name
        ensure_player(name)
        flash(f"Welcome aboard, {name}! 🚀")
    return redirect(url_for("home"))


@app.route("/leaderboard")
def leaderboard():
    player = get_player_name()
    rows = (
        db.session.query(
            GameScore.player_name,
            func.sum(GameScore.score).label("total_score"),
            func.count(GameScore.id).label("games_played"),
        )
        .group_by(GameScore.player_name)
        .order_by(desc("total_score"))
        .limit(50)
        .all()
    )
    game_breakdown = (
        db.session.query(
            GameScore.game_type,
            GameScore.player_name,
            func.max(GameScore.score).label("best_score"),
        )
        .group_by(GameScore.game_type, GameScore.player_name)
        .order_by(desc("best_score"))
        .all()
    )
    return render_template(
        "leaderboard.html",
        rows=rows,
        game_breakdown=game_breakdown,
        games=GAMES,
        player=player,
        personal_bests=get_personal_bests(player),
        game_type_labels=GAME_TYPE_LABELS,
    )


@app.route("/achievements")
def achievements_page():
    player = get_player_name()
    earned = {
        a.badge_id: a.earned_at
        for a in PlayerAchievement.query.filter_by(player_name=player).all()
    }
    progress = get_badge_progress(player)
    return render_template(
        "achievements.html",
        achievements=ACHIEVEMENTS,
        earned=earned,
        progress=progress,
        player=player,
    )


@app.route("/games/<slug>")
def game_page(slug):
    game = next((g for g in GAMES if g["slug"] == slug), None)
    if not game:
        return render_template("404.html", player=get_player_name()), 404

    templates = {
        "pipeline-puzzle": "games/pipeline_puzzle.html",
        "incident-commander": "games/incident_commander.html",
        "dockerfile-builder": "games/dockerfile_builder.html",
        "k8s-yaml-fixer": "games/k8s_yaml_fixer.html",
        "log-detective": "games/log_detective.html",
        "deploy-rollback": "games/deploy_rollback.html",
    }
    context = {
        "game": game,
        "player": get_player_name(),
        "personal_best": get_personal_bests(get_player_name()).get(slug),
        "is_daily": get_daily_game()["slug"] == slug,
    }

    if slug == "pipeline-puzzle":
        shuffled = PIPELINE_STAGES.copy()
        random.shuffle(shuffled)
        context["stages"] = shuffled
        context["correct_order"] = PIPELINE_CORRECT_ORDER
    elif slug == "incident-commander":
        context["scenarios"] = random.sample(
            INCIDENT_SCENARIOS, min(4, len(INCIDENT_SCENARIOS))
        )
    elif slug == "dockerfile-builder":
        context["challenges"] = DOCKERFILE_CHALLENGES
    elif slug == "k8s-yaml-fixer":
        context["challenges"] = K8S_YAML_CHALLENGES
    elif slug == "log-detective":
        context["challenges"] = LOG_CHALLENGES
    elif slug == "deploy-rollback":
        context["scenarios"] = DEPLOY_SCENARIOS

    return render_template(templates[slug], **context)


@app.route("/api/recent-scores")
def api_recent_scores():
    rows = GameScore.query.order_by(desc(GameScore.played_at)).limit(10).all()
    return jsonify(
        [
            {
                **r.to_dict(),
                "game_label": GAME_TYPE_LABELS.get(r.game_type, r.game_type),
            }
            for r in rows
        ]
    )


@app.route("/api/score", methods=["POST"])
def submit_score():
    data = request.get_json(silent=True) or {}
    player = data.get("player_name") or get_player_name()
    game_type = data.get("game_type", "")
    score = int(data.get("score", 0))
    details = data.get("details", "")

    if not game_type:
        return jsonify({"error": "game_type required"}), 400

    # Daily challenge 2× XP bonus
    daily = get_daily_game()
    daily_type = SLUG_TO_GAME_TYPE.get(daily["slug"])
    bonus_applied = False
    if daily_type == game_type:
        score = score * 2
        bonus_applied = True
        details = (details + " [Daily 2×]").strip()

    ensure_player(player)
    record = GameScore(
        player_name=player,
        game_type=game_type,
        score=max(0, score),
        details=details,
    )
    db.session.add(record)

    profile = PlayerProfile.query.filter_by(player_name=player).first()
    if profile:
        profile.games_played += 1
        profile.total_score += max(0, score)

    db.session.commit()
    new_badges = check_achievements(player, game_type, score)
    return jsonify(
        {
            "ok": True,
            "score": score,
            "daily_bonus": bonus_applied,
            "new_badges": [
                {"id": b, **ACHIEVEMENTS[b]} for b in new_badges
            ],
        }
    )


@app.route("/api/leaderboard")
def api_leaderboard():
    rows = (
        db.session.query(
            GameScore.player_name,
            func.sum(GameScore.score).label("total"),
        )
        .group_by(GameScore.player_name)
        .order_by(desc("total"))
        .limit(20)
        .all()
    )
    return jsonify([{"player": r[0], "score": int(r[1])} for r in rows])


# --- Celery demo (kept from original app) ---

mail = Mail(app)
app.config["MAIL_SERVER"] = "smtp.googlemail.com"
app.config["MAIL_PORT"] = 587
app.config["MAIL_USE_TLS"] = True
app.config["MAIL_USERNAME"] = os.environ.get("MAIL_USERNAME")
app.config["MAIL_PASSWORD"] = os.environ.get("MAIL_PASSWORD")
app.config["MAIL_DEFAULT_SENDER"] = "devops-games@example.com"

celery = Celery(app.name, broker=app.config["CELERY_BROKER_URL"])
celery.conf.update(app.config)


@celery.task
def send_async_email(email_data):
    msg = Message(
        email_data["subject"],
        sender=app.config["MAIL_DEFAULT_SENDER"],
        recipients=[email_data["to"]],
    )
    msg.body = email_data["body"]
    with app.app_context():
        mail.send(msg)


@celery.task(bind=True)
def long_task(self):
    verb = ["Deploying", "Rolling back", "Scaling", "Patching", "Migrating"]
    adjective = ["flaky", "blazing", "cursed", "blessed", "chaotic"]
    noun = ["pipeline", "pod", "cluster", "canary", "configmap"]
    message = ""
    total = random.randint(10, 30)
    for i in range(total):
        if not message or random.random() < 0.25:
            message = "{0} {1} {2}...".format(
                random.choice(verb), random.choice(adjective), random.choice(noun)
            )
        self.update_state(
            state="PROGRESS",
            meta={"current": i, "total": total, "status": message},
        )
        time.sleep(1)
    return {
        "current": 100,
        "total": 100,
        "status": "Task completed!",
        "result": 42,
    }


@app.route("/celery", methods=["GET", "POST"])
def celery_worker():
    if request.method == "GET":
        return render_template("celery.html", email=session.get("email", ""))
    email = request.form["email"]
    session["email"] = email
    email_data = {
        "subject": "Hello from DevOps Games",
        "to": email,
        "body": "Your on-call shift starts now. Good luck! 🚨",
    }
    if request.form["submit"] == "Send":
        send_async_email.delay(email_data)
        flash(f"Sending email to {email}")
    else:
        send_async_email.apply_async(args=[email_data], countdown=60)
        flash(f"An email will be sent to {email} in one minute")
    return redirect(url_for("celery_worker"))


@app.route("/longtask", methods=["POST"])
def longtask():
    task = long_task.apply_async()
    return jsonify({}), 202, {"Location": url_for("taskstatus", task_id=task.id)}


@app.route("/status/<task_id>")
def taskstatus(task_id):
    task = long_task.AsyncResult(task_id)
    if task.state == "PENDING":
        response = {"state": task.state, "current": 0, "total": 1, "status": "Pending..."}
    elif task.state == "SUCCESS":
        result = task.result if isinstance(task.result, dict) else {}
        response = {
            "state": task.state,
            "current": result.get("current", 100),
            "total": result.get("total", 100),
            "status": result.get("status", "Task completed!"),
            "result": result.get("result"),
        }
    elif task.state != "FAILURE":
        info = task.info if isinstance(task.info, dict) else {}
        response = {
            "state": task.state,
            "current": info.get("current", 0),
            "total": info.get("total", 1),
            "status": info.get("status", ""),
        }
    else:
        response = {
            "state": task.state,
            "current": 1,
            "total": 1,
            "status": str(task.info),
        }
    return jsonify(response)


if __name__ == "__main__":
    app.run(debug=True)
