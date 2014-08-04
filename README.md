Tournament application API
==========================

Endpoints:  

### Users  
URL: GET /users  
Payload: none  

URL: `GET /users/{id}`
Payload: none

URL: `GET /users/{username}` - Full username or part of it (results in `'LIKE %{username}%'` statement)  
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

URL: `POST /tournaments/{id}/players`  
Payload:  
``` javascript
{  
    "users": [INTEGER, INTEGER, INTEGER] //mandatory - Array of user_ids that you want to add to the tournament  
}  
```

### Matches  
URL: `GET /tournaments/{id}/matches`  
Payload: none  

URL: `POST /tournaments/{id}/matches`  
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