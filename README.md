Tournament application API
==========================

Endpoints:  

### Users  
URL: `GET /users`  
Payload: none  

URL: `GET /users/{id}`
Payload: none

URL: `GET /users/search/{username}` - Full username or part of it (results in `'LIKE %{username}%'` statement)  
Payload: none  

URL: `POST /users`  
Payload:  
``` javascript
{  
    "name":STRING, //mandatory  
    "first_name":STRING, //optional  
    "last_name":STRING //optional  
}  
```

### Tournaments  
URL: `GET /tournaments`  
Payload: none  

URL: `POST /tournaments`  
Payload:  
``` javascript
{  
    "name":STRING, //mandatory  
    "users": [INTEGER, INTEGER, INTEGER] //optional - Array of user_ids that you want to add to the tournament  
}  
```

### Players  
URL: `GET /tournaments/{id}/players`  
Payload: none  

URL: `POST /players`  
Payload:  
``` javascript
{  
    "tournament_id": INTEGER, //mandatory - The id of the tournament you are adding players to  
    "users": [INTEGER, INTEGER, INTEGER] //mandatory - Array of user_ids that you want to add to the tournament  
}  
```

### Matches  
URL: `GET /tournaments/{id}/matches`  
Payload: none  

URL: `POST /matches`  
Payload:  
``` javascript
{  
  "tournament_id": INTEGER,
  "scores":[  
    {  
      "user_id":INTEGER,  
      "games_won":INTEGER  
    },  
    {  
      "user_id":INTEGER,  
      "games_won":INTEGER  
    }  
  ]  
}  
```

Response body:
``` javascript
{  
  "tournament": {  
    "id": INTEGER,  
    "name": STRING,  
    "created_at": DATETIME,  
    "updated_at": DATETIME  
  },  
  "matches": [  
    {  
      "match": {  
        "id": INTEGER,  
          "tournament_id": INTEGER,  
          "created_at": DATETIME,  
          "updated_at": DATETIME  
        },  
      "scores": [  
        {  
          "id": INTEGER,  
          "match_id": INTEGER,  
          "user_id": INTEGER,  
          "games_won": INTEGER,  
          "points": INTEGER,  
          "created_at": DATETIME,  
          "updated_at": DATETIME  
        },  
        {  
          "id": INTEGER,  
          "match_id": INTEGER,  
          "user_id": INTEGER,  
          "games_won": INTEGER,  
          "points": INTEGER,  
          "created_at": DATETIME,  
          "updated_at": DATETIME  
        }  
      ]  
    }  
  ]  
}
```

### Scores
URL: `PUT /matches/:id/scores`
Payload:
``` javascript
{  
  "scores":[  
    {  
      "user_id":INTEGER,  
      "games_won":INTEGER  
    },  
    {  
      "user_id":INTEGER,  
      "games_won":INTEGER  
    }  
  ]  
}  
```