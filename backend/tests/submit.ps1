# http POST :3000/scores user[userId]:=1234567 user[username]=kispy payload[hash]=cool_song_hash payload[score]:=987654 payload[accuracy]:=99.42 payload[combo]:=456 payload[maxCombo]:=500 payload[marvelous]:=420 payload[perfect]:=69 payload[great]:=7 payload[good]:=3 payload[bad]:=1 payload[miss]:=0 payload[grade]=S payload[rating]:=49.34

# Get leaderboard for the song we just submitted a score for
http GET :3000/scores/leaderboard hash==b2fe818ffd885e4579cb7a204f91e86c
