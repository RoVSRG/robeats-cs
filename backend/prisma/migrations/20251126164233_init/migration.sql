-- CreateTable
CREATE TABLE "public"."players" (
    "id" BIGSERIAL NOT NULL,
    "user_id" BIGINT NOT NULL,
    "created_at" TIMESTAMPTZ(6) DEFAULT CURRENT_TIMESTAMP,
    "rating" DOUBLE PRECISION NOT NULL DEFAULT 0,
    "accuracy" DOUBLE PRECISION NOT NULL DEFAULT 0,
    "play_count" INTEGER NOT NULL DEFAULT 0,
    "xp" INTEGER NOT NULL DEFAULT 0,
    "name" TEXT NOT NULL,
    "allowed" BOOLEAN NOT NULL DEFAULT true,

    CONSTRAINT "players_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "public"."scores" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "player_id" BIGINT,
    "hash" TEXT NOT NULL,
    "score" INTEGER NOT NULL DEFAULT 0,
    "accuracy" DOUBLE PRECISION NOT NULL DEFAULT 100,
    "max_combo" INTEGER NOT NULL DEFAULT 0,
    "marvelous" INTEGER NOT NULL DEFAULT 0,
    "perfect" INTEGER NOT NULL DEFAULT 0,
    "great" INTEGER NOT NULL DEFAULT 0,
    "good" INTEGER NOT NULL DEFAULT 0,
    "bad" INTEGER NOT NULL DEFAULT 0,
    "miss" INTEGER NOT NULL DEFAULT 0,
    "grade" TEXT NOT NULL DEFAULT 'F',
    "rating" DOUBLE PRECISION NOT NULL DEFAULT 0,
    "mean" DOUBLE PRECISION NOT NULL DEFAULT 0,
    "created_at" TIMESTAMP(6) DEFAULT CURRENT_TIMESTAMP,
    "rate" INTEGER NOT NULL DEFAULT 100,

    CONSTRAINT "scores_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "players_user_id_key" ON "public"."players"("user_id");

-- CreateIndex
CREATE INDEX "players_allowed_idx" ON "public"."players"("allowed");

-- CreateIndex
CREATE INDEX "scores_hash_idx" ON "public"."scores"("hash");

-- CreateIndex
CREATE INDEX "scores_player_id_idx" ON "public"."scores"("player_id");

-- CreateIndex
CREATE INDEX "scores_hash_player_id_rating_score_idx" ON "public"."scores"("hash", "player_id", "rating" DESC, "score" DESC);

-- CreateIndex
CREATE INDEX "scores_player_id_hash_rating_score_idx" ON "public"."scores"("player_id", "hash", "rating" DESC, "score" DESC);

-- CreateIndex
CREATE INDEX "scores_player_id_hash_created_at_idx" ON "public"."scores"("player_id", "hash", "created_at" DESC);

-- AddForeignKey
ALTER TABLE "public"."scores" ADD CONSTRAINT "scores_player_id_fkey" FOREIGN KEY ("player_id") REFERENCES "public"."players"("id") ON DELETE CASCADE ON UPDATE NO ACTION;
