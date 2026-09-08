-- Synthetic: social network
-- Tests: multiple self-refs on same entity, symmetric junction, asymmetric relations

CREATE TABLE "User" (
    user_id INTEGER PRIMARY KEY,
    username VARCHAR(100) NOT NULL UNIQUE,
    email VARCHAR(255) NOT NULL UNIQUE,
    display_name VARCHAR(255) NOT NULL,
    bio TEXT,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_user_created ON "User"(created_at);

-- Symmetric junction: friendship is bidirectional
-- Invariant: user_a_id < user_b_id (enforced by app, prevents (A,B) + (B,A) dupes)
CREATE TABLE Friendship (
    id INTEGER PRIMARY KEY,
    user_a_id INTEGER NOT NULL REFERENCES "User"(user_id),
    user_b_id INTEGER NOT NULL REFERENCES "User"(user_id),
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(user_a_id, user_b_id)
);

CREATE INDEX idx_friendship_a ON Friendship(user_a_id);
CREATE INDEX idx_friendship_b ON Friendship(user_b_id);

-- Asymmetric: sender → recipient
CREATE TABLE Message (
    message_id INTEGER PRIMARY KEY,
    sender_id INTEGER NOT NULL REFERENCES "User"(user_id),
    recipient_id INTEGER NOT NULL REFERENCES "User"(user_id),
    content TEXT NOT NULL,
    sent_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    read_at TIMESTAMP
);

CREATE INDEX idx_message_sender ON Message(sender_id);
CREATE INDEX idx_message_recipient ON Message(recipient_id);
CREATE INDEX idx_message_sent ON Message(sent_at);

-- Asymmetric: blocker → blocked (directional)
CREATE TABLE Block (
    id INTEGER PRIMARY KEY,
    blocker_id INTEGER NOT NULL REFERENCES "User"(user_id),
    blocked_id INTEGER NOT NULL REFERENCES "User"(user_id),
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(blocker_id, blocked_id)
);

CREATE INDEX idx_block_blocker ON Block(blocker_id);
CREATE INDEX idx_block_blocked ON Block(blocked_id);
