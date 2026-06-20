from datetime import datetime
from flask_sqlalchemy import SQLAlchemy

db = SQLAlchemy()


class GameScore(db.Model):
    __tablename__ = "game_scores"

    id = db.Column(db.Integer, primary_key=True)
    player_name = db.Column(db.String(80), nullable=False, index=True)
    game_type = db.Column(db.String(50), nullable=False, index=True)
    score = db.Column(db.Integer, nullable=False, default=0)
    details = db.Column(db.Text, nullable=True)
    played_at = db.Column(db.DateTime, default=datetime.utcnow, index=True)

    def to_dict(self):
        return {
            "id": self.id,
            "player_name": self.player_name,
            "game_type": self.game_type,
            "score": self.score,
            "details": self.details,
            "played_at": self.played_at.isoformat() if self.played_at else None,
        }


class PlayerAchievement(db.Model):
    __tablename__ = "player_achievements"

    id = db.Column(db.Integer, primary_key=True)
    player_name = db.Column(db.String(80), nullable=False, index=True)
    badge_id = db.Column(db.String(50), nullable=False)
    earned_at = db.Column(db.DateTime, default=datetime.utcnow)

    __table_args__ = (
        db.UniqueConstraint("player_name", "badge_id", name="uq_player_badge"),
    )

    def to_dict(self):
        return {
            "badge_id": self.badge_id,
            "earned_at": self.earned_at.isoformat() if self.earned_at else None,
        }


class PlayerProfile(db.Model):
    __tablename__ = "player_profiles"

    id = db.Column(db.Integer, primary_key=True)
    player_name = db.Column(db.String(80), unique=True, nullable=False)
    games_played = db.Column(db.Integer, default=0)
    total_score = db.Column(db.Integer, default=0)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
