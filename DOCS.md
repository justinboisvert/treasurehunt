## TreasureHunt API

URL can be reached at ec2-18-217-170-237.us-east-2.compute.amazonaws.com:8842

If there is an error when using the endpoint you can check if the "error" key in the returned JSON is true and then read the associated "message" key.

For all methods besides /user/create and /user/login, the session key will have to be included in your header as the "session" parameter.

### /user/create - POST

Creates a user and returns a session key (currently expires in 3 days).

Parameters: username (accepts string), password (accepts string), email (accepts string)

Returned JSON keys: session (string)

### /user/login - POST

Logs user in.

Parameters: username (accepts string), password (accepts string)

Returned JSON keys: session (string)

### /user/logout - POST

Logs user out.

Parameters: None

Return JSON keys: None

### /user/modify - POST

Modifies a specific value for the username. Accepted modifiers are "username", "password", "email" and "pay_id". 

Parameters: modifier (accepts string), value (accepts string)

Returned JSON keys: None

### /map/status - GET

Main feedback loop of the game that gets called to see how close you are to a given prize (if any). 
The current feedback is based on the distance of a prize or if the user received and collected the monetary amount.

Current returned play response in "message"

  NO_CURRENT_GAME
  
  NO_CURRENT_PRIZES
  
  SOMETHING
 
  MELLOW
  
  WARM
 
  SPICY
 
  VERY CLOSE
 
  CLAIMABLE
  
 Parameters: longitude (accepts float), latitude (accepts float)
 
 Returned JSON keys: message
  
 ### /map/claim - POST
 
 Use this method if map/status returns CLAIMABLE to claim a prize. Will return amount claimed
 
 Parameters: longitude (accepts float), latitude (accepts float)
 
 Return JSON keys: amount 
  
 ### /user/redeem_payment - POST
 
Cashes out the amount the username currently has if a payment_id is set. Still work in progress as a reliable and safe payment method to do this is being researched, but the endpoint is currently there for testing purposes for iOS.

Parameters: None

Returned JSON: None

### /user/info - GET

Returns JSON of user info including amount, username, password, email and payment_info.

Parameters: None

Returned JSON keys: info

### /map/hints - GET

Returns hints, if any, of current prizes available.

Parameters: longitude (accepts float) latitude (accepts float)

Returned JSON keys: hints

