curl \
--header 'Authorization: Bearer 6YTDm00xmvYrmPABc6X5Vrtzg2gq0AJf' \
-X POST https://api.pushbullet.com/v2/pushes \
--header 'Content-Type: application/json' \
--data-binary '{"type": "note", "title": "Note Title", "body": "Note Body"}'




curl \
--header 'Authorization: Bearer 6YTDm00xmvYrmPABc6X5Vrtzg2gq0AJf' \
-X POST https://api.pushbullet.com/v2/ephemerals \
--header "Content-Type: application/json" \
--data-binary '{"type": "push", "push": {}}'