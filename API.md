# Unofficial Robinhood API Docs

## Introduction

[Robinhood](http://robinhood.com/) is a free, online securities brokerage. As you would expect, being an online service means everything is handled through a request that is made to a specific URL.

Before I go too far, I must say that this is a big messy work in progress. I'll continue to update this as I figure more out. Sections marked TODO are in my head but I haven't found the time to describe them yet. Work in progress and all.

Oh, and I do not work with or for Robinhood Finacial, LLC. But if they're hiring and see this, [here is my CV](https://s-media-cache-ak0.pinimg.com/736x/5a/7f/94/5a7f94bdb5b359139f5def6870c33466.jpg).

## Table of Contents

This is going to be huge until I get it organized into smaller files so I wish github supported this markdown extention...

[TOC]

## API Security

The HTTPS protocol is used to access the Robinhood API. Transactions require security because most calls transmit actual account informaion. SSL Pinning in used in the official Android and IOS apps to prevent MITM attacks; you would be wise to do the same at the very least.

Calls to API endpoints make use of two different levels of authentication:

1. **None**: No authentication. Anyone can query the method.
2. **Token**: Requires an authorization token generated with a call to [log in](#log-in).

Calls which require no authentication are generally informational ([quote gathering](#quote-methods), [securities lookup](#instrument-methods), etc.).

Authorized calls require an `Authorization` HTTP Header with the authentication type set as `Token` (Example: `Authorization: Token 40charauthozationtokenherexxxxxxxxxxxxxx`).

## API Error Reporting

The API reports incorrect data or imporper use with HTTP staus codes and JSON objects returned as body content. Some that I've run into include:

| HTTP Status | Key                | Value | What I Did Wrong |
|-------------|--------------------|-------|------------------|
| 400         | `non_field_errors` | `["Unable to log in with provided credentials."]` | Attempted to [log in](#logging-in) with incorrect username/password |
| 400         | `password`         | `["This field may not be blank."]`                | Attempted to [log in](#logging-in) without a password |
| 401         | `detail`           | `["Invalid token."]`                              | Attempted to use cached token after [logging out](#logging-out) |
| 400         | `password`           | `["This password is too short. It must contain at least 10 characters.", "This password is too common."]`                                                       | Attempted to [change my password](#password-reset) to `password` |

...you get the idea. Letting you know exactly what went wrong makes the API almost self-documenting so thanks Robinhood.

## Authentication Methods

Most calls to the API will require an authorization token. After logging in, you should store the token in a secure way for future calls without forcing users to log in again.

### Logging in

If you plan to do much beyond requesting [quote data](#quote-methods), you'll need to log in and use the authorization token. Once generated, all log ins to your account are given the same token until you [log out](#logging-out).

**Method**

| URI                               | HTTP Method | Authentication |
|-----------------------------------|-------------|----------------|
| api.robinhood.com/api-token-auth/ | POST        |	None           |

**Fields**

| Parameter | Type   | Description   | Default | Required |
|-----------|--------|---------------|---------|----------|
| username  | String | Your username | N/A     | **Yes**  |
| password  | String | Uh, password  | N/A     | **Yes**  |

**Request sample**

```
curl -v https://api.robinhood.com/api-token-auth/ \
   -H "Accept: application/json" \
   -d "username={username}&password={password}"
```

**Response**

| Key   | Type   |Description|
|-------|--------|-----------|
| token | String | The authorization token you must pass to all calls which require authentication |

**Response sample**

```
{
  "token": "a9a7007f890c790a30a0e0f0a7a07a0242354114"
}
```

### Logging out

Every client that [logs in](#log-in) with your username/password is given the same token. For security, you can force it to expire with a call to log out.

**Method**

| URI                                 | HTTP Method | Authentication |
|-------------------------------------|-------------|----------------|
| api.robinhood.com/api-token-logout/ | POST        |	Token        |

**Request sample**

```
curl -v https://api.robinhood.com/api-token-logout/ \
   -H "Accept: application/json" \
   -H "Authorization: Token a9a7007f890c790a30a0e0f0a7a07a0242354114"
   -d ""
```

**Response**

*On success, no content is returned.*

### Password Reset Request

We all forget our password. This will have a reset request sent to your email address.

**Method**

| URI                                       | HTTP Method | Authentication |
|-------------------------------------------|-------------|----------------|
| api.robinhood.com/password_reset/request/ | POST        |	None           |

**Fields**

| Parameter | Type   | Description                 | Default | Required |
|-----------|--------|-----------------------------|---------|----------|
| email     | String | Address you registered with | N/A     | **Yes**  |

**Request sample**

```
curl -v https://api.robinhood.com/password_reset/request/ \
   -H "Accept: application/json" \
   -d "email={email}"
```

**Response**

| Key    | Type   | Description |
|--------|--------|-------------|
| link   | URL    | Link to the actual [reset URL](#password-reset) |
| detail | String | Message you could display in your UI |

*Note that this will always claim to be sending a reset email for brute force security reasons.*

**Response sample**

```
{
    "link": "https://api.robinhood.com/password_reset/",
    "detail": "Email with password reset instructions sent!"
}
```

### Password Reset

After requesting a password reset, an email is sent with a link that allows you to set a new password. This is that link on the API side.

**Method**

| URI                               | HTTP Method | Authentication |
|-----------------------------------|-------------|----------------|
| api.robinhood.com/password_reset/ | POST        |	None           |

**Fields**

| Parameter | Type   | Description                                         | Default | Required |
|-----------|--------|-----------------------------------------------------|---------|----------|
| username  | String | The username associated with the email address      | N/A     | *Yes*    |
| token     | String | Reset token provided by Robinhood in the reset link | N/A     | *Yes*    |
| password  | String | New password                                        | N/A     | *Yes*    |

**Request sample**

```
curl -v https://api.robinhood.com/password_reset/request/ \
   -H "Accept: application/json" \
   -d "username=contact@example.com&password=10CharsPls&token=defacedefacedefacefe-a-f-af01286fd-acef8
```

**Response**

*Untested*

**Response sample**

*Untested*

## User Information Methods

Now that you're [logged in](#logging-in), you'll probably want to get to know yourself a little bit. Here we go...

### Gather Basic User Info

This returns very basic information (basically just a name and email address) and URLs for more.

**Method**

| URI                     | HTTP Method | Authentication |
|-------------------------|-------------|----------------|
| api.robinhood.com/user/ | GET         | *Yes*          |

**Fields**

AFAIK, there are none.

**Request sample**

```
curl -v https://api.robinhood.com/user/ \
   -H "Accept: application/json" \
   -H "Authorization: Token a9a7007f890c790a30a0e0f0a7a07a0242354114"
```

**Response**

| Key    | Type   | Description |
|--------|--------|-------------|
| username   | String | The username of the currently logged in account |
| first_name | String | First name of the registered user               |
| last_name  | String | Last name of the registered user                |
| id_info    | URL    | Link to use for more information                |
| url        | URL    | This exact URL in case you forget what you just did |
| basic_info | URL    | Link where more basic information may be gathered   |
| email      | String | Email address of the currently logged in account    |
| investment_profile | URL | Link where investment related info may be gathered |
| id         | String | The unique ID Robinhood uses to identify this account   |
| international_info | URL | International... stuff? |
| employment | URL | Employment information you provided may be found here |
| additional_info | URL | Need more information? Grab it here! |

**Response sample**
```
{
    "username": "superman",
    "first_name": "Clark",
    "last_name": "Kent",
    "id_info": "https://api.robinhood.com/user/id/",
    "url": "https://api.robinhood.com/user/",
    "basic_info": "https://api.robinhood.com/user/basic_info/",
    "email": "s@itmeanshope.com",
    "investment_profile": "https://api.robinhood.com/user/investment_profile/",
    "id": "11deface-face-face-face-defacedeface11",
    "international_info": "https://api.robinhood.com/user/international_info/",
    "employment": "https://api.robinhood.com/user/employment/",
    "additional_info": "https://api.robinhood.com/user/additional_info/"
}
```

### Gather the Account ID

Robinhood uses a unique ID for each account. You could use the basic [/user/](#gather-basic-user-info) to get this ID and more by the way.

**Method**

| URI                        | HTTP Method | Authentication |
|----------------------------|-------------|----------------|
| api.robinhood.com/user/id/ | GET         | *Yes*          |

**Fields**

AFAIK, there are none.

**Request sample**

```
curl -v https://api.robinhood.com/user/id/ \
   -H "Accept: application/json" \
   -H "Authorization: Token a9a7007f890c790a30a0e0f0a7a07a0242354114"
```

**Response**

| Key    | Type   | Description |
|--------|--------|-------------|
| username   | String | The username of the currently logged in account |
| url        | URL    | This exact URL in case you forget what you just did |
| id         | String | The unique ID Robinhood uses to identify this account   |

**Response sample**
```
{
    "username": "superman",
    "url": "https://api.robinhood.com/user/id/",
    "id": "11deface-face-face-face-defacedeface11"
}
```

### Gather Basic Information About the Account Holder

If you need more than the basic information [/user/](#gather-basic-user-info) provides, you might want to start here.

**Method**

| URI                                | HTTP Method | Authentication |
|------------------------------------|-------------|----------------|
| api.robinhood.com/user/basic_info/ | GET         | *Yes*          |

**Fields**

AFAIK, there are none.

**Request sample**

```
curl -v https://api.robinhood.com/user/basic_info/ \
   -H "Accept: application/json" \
   -H "Authorization: Token a9a7007f890c790a30a0e0f0a7a07a0242354114"
```

**Response**

| Key                  | Type     | Description |
|----------------------|----------|-------------|
| address              | String   | Street address |
| citizenship          | String   | Two character country code |
| city                 | String   | The unique ID Robinhood uses to identify this account |
| country_of_residence | String   | To character country code |
| date_of_birth        | String   | Date of your birth |
| marital_status       | String   | Are you `married` or `single`. Only Facebook cares if it's `complicated` |
| number_dependents    | Integer  | How many kids do you have? |
| phone_number         | Integer  | Digits |
| state                | String   | Two character state abbreviation |
| tax_id_ssn           | Integer  | Last four digits of your Social Security Number |
| updated_at           | ISO 8601 | When was any of this information last modified |
| zipcode              | Integer  | Postal zip code of your current location |

**Response sample**
```
{
    "phone_number": "2125550030",
    "city": "New York",
    "number_dependents": 2,
    "citizenship": "US",
    "updated_at": "2016-03-13T12:18:02.820164Z",
    "marital_status": "married",
    "zipcode": "10001",
    "country_of_residence": "US",
    "state": "NY",
    "date_of_birth": "1978-12-18",
    "user": "https://api.robinhood.com/user/",
    "address": "320 10th Av",
    "tax_id_ssn": "0001"
}
```

### Account Holder's Affiliation Information

If you need more than the basic information [/user/](#gather-basic-user-info) provides, you might want to start here. This method returns SEC Rule 405 related information.

**Method**

| URI                                     | HTTP Method | Authentication |
|-----------------------------------------|-------------|----------------|
| api.robinhood.com/user/additional_info/ | GET         | *Yes*          |

**Fields**

AFAIK, there are none.

**Request sample**

```
curl -v https://api.robinhood.com/user/additional_info/ \
   -H "Accept: application/json" \
   -H "Authorization: Token a9a7007f890c790a30a0e0f0a7a07a0242354114"
```

**Response**

| Key                			  		| Type     | Description |
|---------------------------------------|----------|-------------|
| control_person       					| Boolean  | Are you a controlling member of any traded securities? |
| control_person_security_symbol 		| String   | If so, the symbol will be here |
| object_to_disclosure 			 		| Boolean  | |
| security_affiliated_address 			| String   | |
| security_affiliated_employee 			| Boolean  | |
| security_affiliated_firm_name 		| String   | |
| security_affiliated_firm_relationship | String   | |
| security_affiliated_person_name		| String   | |
| sweep_consent 						| Boolean  | |
| updated_at           					| ISO 8601 | When was any of this information last modified |
| user 									| URL 	   | Link back to the `/user/` endpoint |

**Response sample**
```
{
    "security_affiliated_firm_relationship": "NA",
    "security_affiliated_employee": false,
    "security_affiliated_address": "",
    "object_to_disclosure": false,
    "updated_at": "2016-01-09T04:13:09.164027Z",
    "control_person": false,
    "sweep_consent": false,
    "user": "https://api.robinhood.com/user/",
    "control_person_security_symbol": "",
    "security_affiliated_firm_name": "NA",
    "security_affiliated_person_name": "NA"
}
```

### Gather Employment Data About the Account Holder

This returns the work status and related information.

**Method**

| URI                                | HTTP Method | Authentication |
|------------------------------------|-------------|----------------|
| api.robinhood.com/user/employment/ | GET         | *Yes*          |

**Fields**

AFAIK, there are none.

**Request sample**

```
curl -v https://api.robinhood.com/user/employment/ \
   -H "Accept: application/json" \
   -H "Authorization: Token a9a7007f890c790a30a0e0f0a7a07a0242354114"
```

**Response**

| Key          		| Type     | Description |
|-------------------|----------|-------------|
| employer_address  | String   | Postal address of your place of work |
| employer_city 	| String   | City where your employer is located |
| employer_name 	| String   | |
| employer_state 	| String   | |
| employer_zipcode 	| Integer  | |
| employment_status | String   | |
| occupation 		| String   | |
| updated_at    	| ISO 8601 | When was any of this information last modified |
| user 				| URL 	   | Link back to the `/user/` endpoint |
| years_employed	| Integer  | How long have you had your current job? |

** Response sample**
```
{
    "employer_zipcode": 12401"",
    "employment_status": "employed",
    "employer_address": "3559 High Street",
    "updated_at": "2015-12-05T12:19:35.028461Z",
    "employer_name": "Bob's Job Palace",
    "user": "https://api.robinhood.com/user/",
    "years_employed": 3,
    "employer_state": "NY",
    "employer_city": "Kingston",
    "occupation": "Getaway Driver"
}
```

### Gather Investment Profile Data About the Account Holder

This returns answers to the basic investing experience survery presented during registration.

**Method**

| URI                                        | HTTP Method | Authentication |
|--------------------------------------------|-------------|----------------|
| api.robinhood.com/user/investment_profile/ | GET         | *Yes*          |

**Fields**

AFAIK, there are none.

**Request sample**

```
curl -v https://api.robinhood.com/user/investment_profile/ \
   -H "Accept: application/json" \
   -H "Authorization: Token a9a7007f890c790a30a0e0f0a7a07a0242354114"
```

**Response**

| Key          	    	| Type     | Description |
|-----------------------|----------|-------------|
| annual_income         | String   | `0_24999`, `25000_39999`, `40000_49999`, `50000_74999`, `75000_99999`, `100000_199999`, `200000_299999`, `300000_499999`, `500000_1199999`, or `1200000_inf` |
| investment_experience | String   | `extensive_investment_exp`, `good_investment_exp`, `limited_investment_exp`, or `no_investment_exp` |
| investment_objective 	| String   | `cap_preserve_invest_obj`, `income_invest_obj`, `growth_invest_obj`, `speculation_invest_obj`, `other_invest_obj` |
| liquid_net_worth      | String   | `0_24999`, `25000_39999`, `40000_49999`, `50000_99999`, `100000_199999`, `200000_249999`, `250000_499999`, `500000_999999`, or `1000000_inf` |
| liquidity_needs 	    | String   | `not_important_liq_need`, `somewhat_important_liq_need`, or `very_important_liq_need` |
| risk_tolerance 	    | String   | `low_risk_tolerance`, `med_risk_tolerance`, or `high_risk_tolerance` |
| source_of_funds       | String   | `savings_personal_income`, `pension_retirement`, `insurance_payout`, `inheritance`, `gift`, `sale_business_or_property`, or `other` |
| suitability_verified 	| Boolean  | |
| tax_bracket			| String   | `0_pct`, `20_pct`, `25_pct`, `28_pct`, `33_pct`, `35_pct`, or `39_6_pct` |
| time_horizon			| String   | `short_time_horizon`, `med_time_horizon`, or `long_time_horizon` |
| total_net_worth		| String   | `0_24999`, `25000_49999`, `50000_64999`, `65000_99999`, `100000_149999`, `150000_199999`, `250000_499999`, `500000_999999`, or `1000000_inf` |
| updated_at    		| ISO 8601 | When was any of this information last modified |
| user 					| URL 	   | Link back to the `/user/` endpoint |

** Response sample**
```
{
    "annual_income": "40000_49999",
    "investment_experience": "good_investment_exp",
    "updated_at": "2016-01-06T14:35:47.015871Z",
    "risk_tolerance": "high_risk_tolerance",
    "total_net_worth": "100000_149999",
    "liquidity_needs": "very_important_liq_need",
    "investment_objective": "other_invest_obj",
    "source_of_funds": "savings_personal_income",
    "user": "https://api.robinhood.com/user/",
    "suitability_verified": true,
    "tax_bracket": "",
    "time_horizon": "long_time_horizon",
    "liquid_net_worth": "100000_199999"
}
```

### Gather Verifiable User Information

Use this endpoint to get personal information that may be used to verify a person's identity.

**Method**

| URI                                        | HTTP Method | Authentication |
|--------------------------------------------|-------------|----------------|
| api.robinhood.com/user/identity_mismatch/ | GET         | *Yes*          |

**Fields**

AFAIK, there are none.

**Request sample**

```
curl -v https://api.robinhood.com/user/identity_mismatch/ \
   -H "Accept: application/json" \
   -H "Authorization: Token a9a7007f890c790a30a0e0f0a7a07a0242354114"
```

**Response**

This returns a [paginated list](#pagination) of data with the following results:

| Key   | Type   | Description |
|-------|--------|-------------|
| field | String | The key (name) of the valid information |
| url   | URL    | URL you may use to gather the valid information |

** Response sample**
```
{
    "field": "tax_id_ssn",
    "url": "https://api.robinhood.com/user/basic_info/"
}
```

### Get the Customer Identification Program Questions

Banks stuff...

**Method**

| URI                                   | HTTP Method | Authentication |
|---------------------------------------|-------------|----------------|
| api.robinhood.com/user/cip_questions/ | GET         | *Yes*          |

**Fields**

AFAIK, there are none.

**Request sample**

```
curl -v https://api.robinhood.com/user/cip_questions/ \
   -H "Accept: application/json" \
   -H "Authorization: Token a9a7007f890c790a30a0e0f0a7a07a0242354114"
```

**Response**

_Unsure. I get..._

```
{ detail => "Not found." }
```

** Response sample**

_Untested_

### Answer Customer Identification Program Questions

Banks stuff...

**Method**

| URI                                   | HTTP Method | Authentication |
|---------------------------------------|-------------|----------------|
| api.robinhood.com/user/cip_questions/ | PUT         | *Yes*          |

**Fields**

AFAIK, there are none.

**Request sample**

_Untested_

**Response**

_Untested_

** Response sample**

_Untested_

### Update User Information

Banks stuff...

**Method**

| URI                     | HTTP Method | Authentication |
|-------------------------|-------------|----------------|
| api.robinhood.com/user/ | PUT         | *Yes*          |

**Fields**

AFAIK, there are none.

**Request sample**

```
curl -v https://api.robinhood.com/user/ \
   -X PUT
   -H "Accept: application/json" \
   -H "Authorization: Token a9a7007f890c790a30a0e0f0a7a07a0242354114"
   -d username={username}  -d password={password}
   -d email={email}
   -d first_name={first_name} -d last_name={last_name}
```

**Fields**

| Parameter  | Type   | Description                                     | Default | Required |
|-------------|--------|------------------------------------------------|---------|----------|
| username    | String | The username associated with the email address | N/A     | *Yes*    |
| password    | String | New password                                   | N/A     | *Yes*    |
| email       | String | You know what this is...                       | N/A     | *Yes*    |
| first_name  | String | Obvious                                        | N/A     | *Yes*    |
| last_name   | String | Obvious                                        | N/A     | *Yes*    |

**Response**

_Untested_

** Response sample**

_Untested_

#### TODO

- Update Basic Info				`PATCH /user/basic_info/`
- Update User					`PATCH /user/`
- Submit Additional User Info	`PUT /user/additional_info/`
- Submit Basic User Info		`PUT /user/basic_info/`
- Submit User Employment Info	`PUT /user/employment/`
- Submit Investment Profile		`PUT /user/investment_profile/`
- Get Application By Type		`GET /applications/$type/`
- Get Applications				`GET /applications/`

### Notification Settings

Push notifications are amazing. You gotta figure this out yourself.

#### TODO

- Get Notification Settings		`GET /settings/notifications/`
- Put Notification Settings		`PUT /settings/notifications/`
- Add Device					`POST /notifications/devices/`
- Delete device					`DELETE /notifications/devices/{deviceId}/`
- Get Devices					`GET /notificatins/devices/`

### Account Methods

Most account API calls require an `account_id` so the service knows which of your accounts to act on.

### Gather List of Accounts

I don't know if Robinhood will allow multiple accounts per user in the future, but this endpoint returns a paginated list of accounts so... maybe. I'd love to have access to both a cash and Instant (margin) account.

**Method**

| URI                         | HTTP Method | Authentication |
|-----------------------------|-------------|----------------|
| api.robinhood.com/accounts/ | GET         | *Yes*          |

**Fields**

AFAIK, there are none.

**Request sample**

```
curl -v https://api.robinhood.com/accounts/ \
   -H "Accept: application/json" \
   -H "Authorization: Token a9a7007f890c790a30a0e0f0a7a07a0242354114"
```

**Response**

A [paginated](#pagination) list of accounts is returned. Accounts contain the following keys...

| Key                           | Type     | Description |
|-------------------------------|----------|-------------|
| deactivated      				| Boolean  | Not sure what Robinhood would deactivate an account for but apparently they have the option |
| updated_at       				| ISO 8601 | Last time the account was modified. I presume this includes cash amount changes as well. |
| margin_balances  				| Hash     | See below |
| portfolio        				| URL      | This URL is the endpoint for this account's portfolio. Wow, I know. |
| cash_balances    				| Hash     | See below |
| withdrawl_halted 			    | Boolean  | Has the most recent attempt to withdrawl cash been stopped |
| cash_available_for_withdrawal | Float    | Amount of money on hand you may withdrawal to your back via ACH |
| type             				| String   | If normal Robinhood accounts would be `cash` but Instant accounts would obviously be `margin` |
| sma 							| Unknown  | `null` for me so I have no idea how it'l be presented. Should be a Boolean? |
| sweep_enabled					| Boolean  | |
| deposit_halted				| Boolean  | |
| buying_power 					| Float    | Amount of cash on hand for purchasing securities (T+3 settled funds not being held for orders) |
| user 							| URL      | Link back to the basic [user data endpoint](#gather-basic-user-info) |
| max_ach_early_access_amount	| Float    | Amount of cash you may use before the actual transfer completes (Instant account perhaps?) |
| cash_held_for_orders 			| Float    | This is the total amount of money marked for use in outstanding buy orders. |
| only_position_closing_trades  | Boolean  | Google 'investopedia close position' |
| url 							| URL 	   | Endpoint where more information about this account may be grabbed |
| positions						| URL 	   | Endpoint where you may grab the past/current positions held by this account |
| created_at					| ISO 8601 | When was the account created |
| cash 							| Float    | Amount of cash including unsettled funds |
| sma_held_for_orders 			| Unknown  | Google 'investopedia "special memorandum account"' |
| account_number                | String   | The actual alphanumeric string Robinhood uses to identify this account |
| uncleared_deposits            | Float    | Amount of money in transet from an inconplete ACH deposit |
| unsettled_funds               | Float    | Amount of money being held in statis thanks to the SEC's T+3 anti-fun rule |

**`cash_balances`**

This is a hash with the following keys... A lot of these are copies of data found in the account object itself though... just, FYI...

| Key             | Type     | Description |
|-----------------|----------|-------------|
| cash_held_for_orders | Float  | This is the total amount of money marked for use in outstanding buy orders. |
| created_at      | ISO 8601 | When was the cash account created |
| cash | Float     | Amount of cash including unsettled funds |
| buying_power | Float | Amount of cash on hand for purchasing securities (T+3 settled funds not being held for orders) |
| updated_at       | ISO 8601      | When any of the values of `cash_balances` was last changed |
| cash_available_for_withdrawl   | Float   | Amount of cash on hand you may transfer to your connected ACH account |
| uncleared_deposits | Float | Value of all initiated ACH transfers which have not completed |
| unsettled_funds | Float | Amount of money being held in statis thanks to SEC's T+3 anti-fun rule |

**`margin_balances`**

_I assume this is a hash much like `cash_balances` but I do not have an Instant account yet so it's simply `null`_

** Response sample**

```
{
	"next": null,
    "previous": null,
	"results": [{
    	"deactivated": false,
    	"updated_at": "2015-09-25T18:43:10.879108Z",
    	"margin_balances": null,
    	"portfolio": "https://api.robinhood.com/accounts/8UD09348/portfolio/",
    	"cash_balances": {
    	    "cash_held_for_orders": "0.0000",
    	    "created_at": "2016-03-12T01:98:27.672943Z",
    	    "cash": "214.8900",
    	    "buying_power": "114.8900",
    	    "updated_at": "2016-03-18T09:03:59.0954927Z",
    	    "cash_available_for_withdrawal": "114.8900",
    	    "uncleared_deposits": "0.0000",
	        "unsettled_funds": "100.0000"
    	},
    	"withdrawal_halted": false,
    	"cash_available_for_withdrawal": "114.8900",
    	"type": "cash",
    	"sma": null,
    	"sweep_enabled": false,
    	"deposit_halted": false,
    	"buying_power": "114.8900",
    	"user": "https://api.robinhood.com/user/",
    	"max_ach_early_access_amount": "0.00",
    	"cash_held_for_orders": "0.0000",
    	"only_position_closing_trades": false,
    	"url": "https://api.robinhood.com/accounts/8UD09348/",
    	"positions": "https://api.robinhood.com/accounts/8UD09348/positions/",
    	"created_at": "2016-03-12T01:98:27.672943Z",
    	"cash": "114.8900",
    	"sma_held_for_orders": null,
    	"account_number": "8UD09348",
    	"uncleared_deposits": "0.0000",
    	"unsettled_funds": "100.0000"
	}]
}
```

#### TODO
	- Create Sweep Account			PUT  /user/additional_info/ 		{sweep_consent}
	- Account Application			PUT  /applications/individual/		???
	- Upgrade To Margin				POST /margin/upgrades/						???
	- Get Instant Eligibility		GET /midlands/permissions/instant/
	- Get Recent Day Trades			GET /accounts/$id/recent_day_trades/?cursor=$cursor
	- Get Day Trade Check			GET /accounts/$id/day_trade_checks/?instrument=$id
	- Get Margin Settings			GET /settings/margin/$accountNumber/
	- Get Margin Upgrades			GET /margin/upgrades/
	- Get Account					GET /accounts/$id/

### Update Day Trade Setting

#### TODO

    PATCH	/settings/margin/{acctNumber}/
	
    
    {$margin_settings}

### Sign-up Referrals

#### TODO
	- Get Referral Campaign Info	GET /midlands/referral/instand/information/
	- Get Referral Code				GET /midlands/referral/code/
	- Get Referrals					GET /midlands/referral/instand/referrals/?curosr=$cursor
	- Establish Referral			POST /midlands/referral/instant/	???

### News & Information
#### TODO
	- Get Robinhood Disclosure		GET /disclosures/home_screen_disclosures.json
	- Get Popular Stocks			GET /popular_stocks/data.json
	- Get Top Movers on the S&P500	GET /midlands/movers/sp500/?direction=['up' or 'down'] 
	- Get News						GET /midlands/news/$instrumentSymbol/

### Cards
#### TODO
	- Gather list of cards			GET  /midlands/notifications/stack/
	- Dismiss Card					POST /midlands/notifications/stack/$cardId/dismiss/

### Market Information
#### TODO
	- Get Market					GET /markets/$mic/
	- Get Market Hours				GET /markets/$mic/hours/$date/
	- Get Markets					GET /markets/

### Dividends
#### TODO
	- Get Dividend					GET /dividends/$dividendId/
	- Get Dividends					GET /dividends/						{cursor}

### Portfolio and Positions
#### TODO
	- List Portfolios               GET /portfolios/
	- Get Portfolio					GET /portfolios/$accountNumber/
	- Get Portfolio Historicals		GET /portfolios/historicals/$accountNumber?span=...&interval=...
	- Get Position					GET /positions/$accountNumber/$instrumentId/
	- Get Positions					GET /accounts/{account_id}/positions/?nonzero=true&cursor=[$cursor]
	- Reorder Positions				GET /positions/?ordering=$ordering

### Bank Accounts & ACH Transfers

#### TODO

	- Get ACH Relationship			GET /ach/relationships/$achRelationshipId/
	- Get ACH Relationships			GET /ach/relationships/				{cursor => optional}
	- Get ACH Transfer				GET /ach/transfers/$id/
	- Get ACH Transfers				GET /ach/transfers/					{cursor => optional}
	- Get Auto Deposit				GET /ach/deposit_schedules/$automaticDepositId/
	- Get Auto Deposits				GET /ach/deposit_schedules/
	- Verify Microdeposits			POST /ach/relationships/$id/micro_deposits/veryify/	{first_amount_cents, second_amount_cents}
	- Get Queued ACH Deposit		GET /ach/iav/queued_deposit/
	- Post ACH Transfer				POST /ach/transfers/  											{???}
	- IAV AuthMfaAnswer				POST /ach/iav/auth/mfa/					{bank_institution, access_token, mfa}
	- IAV Auth Request				POST /ach/iav/auth/						{bank_institution, username, password, pin}
	- Post Queued ACH Deposit		POST /ach/iav/queued_deposit/
	- Delete Auto Deposit			DELETE /ach/deposit_schedules/$autoDepositId/
	- Cancel ACH Transfer			POST /ach/transfers/$id/cancel/
	- Add ACH Bank account			POST /ach/relationships/			{account ($account_id)
																		 bank_routing_number
																		 bank_account_number
																		 bank_account_type ('checking' or 'savings')
																		 bank_account_holder_name
																		 bank_account_nickname
																		}
	- Add ACH with Instant Acct Verification	POST /ach/iav/create/				{access_token
																		 iav_account_id
																		 account ($account_id)
																		 bank_account_type ('checking' or 'savings')
																		 bank_account_holder_name
																		}
	- Delete Bank Account			POST /ach/relationships/$bankId/unlink/

### Place an Order

Buy and sell shares of securities!

**Method**

| URI                       | HTTP Method | Authentication |
|---------------------------|-------------|----------------|
| api.robinhood.com/orders/ | POST        | *Yes*          |

**Fields**


| Parameter     | Type   | Description                                         		          | Default |Required|
|---------------|--------|--------------------------------------------------------------------|---------|--------|
| account       | URL    | Account to make this order with      				              | N/A     | *Yes*  |
| instrument    | URL    | Instrument URL of the security you're attempting to buy or sell    | N/A     | *Yes*  |
| symbol        | String | The ticker symbol of the security you're attmepting to buy or sell | N/A     | *Yes*  |
| type 		    | String | Order type: `market` or `limit`                                    | N/A     | *Yes*  |
| time_in_force | String | `gfd`, `gtc`, `ioc`, `fok` or `opg`                                | N/A     | *Yes*  |
| trigger	    | String | `immediate`, `stop`, or `on_close`                                 | N/A     | *Yes*  |
| price		    | Float  | The price you're willing to accept in a sell or pay in a buy       | N/A     | Only when `type` equals `limit`   |
| stop_price    | Float  | The price at which an order with a `stop` trigger converts         | N/A     | Only when `trigger` equals `stop` |
| quantity      | Int    | Number of shares you would like to buy or sell                     | N/A     | *Yes*  |
| side          | String | `buy` or `sell`                                                    | N/A     | *Yes*  |
| client_id     | String | Only available for OAuth applications                              | N/A     | No     |

**Request sample**

```
curl -v https://api.robinhood.com/orders/ \
   -H "Accept: application/json" \
   -H "Authorization: Token a9a7007f890c790a30a0e0f0a7a07a0242354114" \
   -d account=https://api.robinhood.com/accounts/8UD09348/ \
   -d instrument=https://api.robinhood.com/instruments/50810c35-d215-4866-9758-0ada4ac79ffa/ \
   -d symbol=MSFT \
   -d type=market \
   -d time_in_force=fok \
   -d trigger=immediate \
   -d quantity=1 \
   -d side=sell
```

**Response**

Fields are returned as well as the following:

| Key          		| Type     | Description |
|-------------------|----------|-------------|
| updated_at        | ISO 8601 |  |
| executions        | Array    | This is a list of hashes |
| fees              | Float    | Total fees including. Generally `0.00` |
| cancel            | URL      | If this is not `null`, you can `POST` to this URL to cancel the order |
| id                | String   | Internal id of this order |
| cumulative_quantity | Float  | Number of shares which have executed so far |
| reject_reason     | String   ||
| state             | String   |  `queued`, `unconfirmed`, `confirmed`, `partially_filled`, `filled`, `rejected`, `canceled`, or `failed` |
| last_transaction_at | ISO 8601 ||
| client_id         | String ||
| url               | URL | Link to this order with up to date information |
| created_at        | ISO 8601 | Time the order was placed |
| position          | URL | Link to positions for this account with this instrument |
| average_price     | Float | Average price of all shares executed so far |

** Response sample**
```
{
    "updated_at": "2016-04-01T21:24:13.698563Z",
    "executions": [],
    "time_in_force": "fok",
    "fees": "0.00",
    "cancel": "https://api.robinhood.com/orders/15390ade-face-caca-0987-9fdac5824701/cancel/",
    "id": "15390ade-face-caca-0987-9fdac5824701",
    "cumulative_quantity": "0.00000",
    "stop_price": null,
    "reject_reason": null,
    "instrument": "https://api.robinhood.com/instruments/50810c35-d215-4866-9758-0ada4ac79ffa/",
    "state": "queued",
    "trigger": "immediate",
    "type": "market",
    "last_transaction_at": "2016-04-01T23:34:54.237390Z",
    "price": null,
    "client_id": null,
    "account": "https://api.robinhood.com/accounts/8UD09348/",
    "url": "https://api.robinhood.com/orders/15390ade-face-caca-0987-9fdac5824701/",
    "created_at": "2016-04-01T22:12:14.890283Z",
    "side": "sell",
    "position": "https://api.robinhood.com/positions/8UD09348/50810c35-d215-4866-9758-0ada4ac79ffa/",
    "average_price": null,
    "quantity": "1.00000"
}
```

### Gather Order Information

This returns the work status and related information.

**Method**

| URI                                 | HTTP Method | Authentication |
|-------------------------------------|-------------|----------------|
| api.robinhood.com/orders/{order_id} | GET         | *Yes*          |

**Fields**

AFAIK, there are none.

**Request sample**

```
curl -v https://api.robinhood.com/user/employment/ \
   -H "Accept: application/json" \
   -H "Authorization: Token a9a7007f890c790a30a0e0f0a7a07a0242354114"
```

**Response**

See the response to [placing an order](#place-an-order).

** Response sample**

See the response sample to [placing an order](#place-an-order).

### Gather Recent Orders

This returns the work status and related information.

**Method**

| URI                       | HTTP Method | Authentication |
|---------------------------|-------------|----------------|
| api.robinhood.com/orders/ | GET         | *Yes*          |


	- 			- Get Orders					GET /orders/?updated_at=[gte]&cursor=[$cursor]
- 			- Get Orders By Instrument		GET /orders/updated_at=[gte]&cursor=[$cursor]&instrument=$instrument

**Parameters**

| Parameter       | Type     | Description                         		          | Default |Required|
|-----------------|----------|----------------------------------------------------|---------|--------|
| updated_at[gte] | ISO 8601 | Timestamp of earliest order we want information on | N/A     | No     |
| instrument      | String   | Instrument we want information on (ID not Url)     | N/A     | No     |
| cursor          | String   | Orders are returned as a paginated list            | N/A     | No     | 

**Request sample**

```
curl -v https://api.robinhood.com/orders/ \
   -H "Accept: application/json" \
   -H "Authorization: Token a9a7007f890c790a30a0e0f0a7a07a0242354114"
```

**Response**

TODO

** Response sample**

TODO

### Cancel an Order

This returns the work status and related information.

**Method**

| URI                                         | HTTP Method | Authentication |
|---------------------------------------------|-------------|----------------|
| api.robinhood.com/orders/{order_id}/cancel/ | POST         | *Yes*          |

**Fields**

AFAIK, there are none.

**Request sample**

```
curl -v https://api.robinhood.com/orders/15390ade-face-caca-0987-9fdac5824701/cancel/ \
   -H "Accept: application/json" \
   -H "Authorization: Token a9a7007f890c790a30a0e0f0a7a07a0242354114"
   -d ""
```

**Response**

See the response to [placing an order](#place-an-order).

** Response sample**

See the response sample to [placing an order](#place-an-order).

### Document Access
#### TODO
	- Get Document Info by ID		GET /documents/$id/
	- Get Document Download URL		GET /documents/$id/download/
	- Get Documents					GET /documents/
	- Mark Doc Request Uploaded		PATCH /upload/document_request/$rhid/?state=$state

### Watchlists

You can organize and keep track of securities in named watchlists.

By the way, the default wishlist used by Robinhood's iOS and Android apps is called 'Default' so you may want to avoid deleting that one.

#### Bulk Add Instruments by Symbol

You can add multiple instruments to a watchlist as a comma separated list of symbols.

**Method**

| URI                                                     | HTTP Method | Authentication |
|---------------------------------------------------------|-------------|----------------|
| api.robinhood.com/watchlists/{watchlist_name}/bulk_add/ | POST        | *Yes*          |

**Fields**

| Parameter     | Type   | Description                                       | Default |Required|
|---------------|--------|---------------------------------------------------|---------|--------|
| symbols       | String | Comma separated list of ticker symbols (up to 32) | N/A     | *Yes*  |

**Request sample**

```
curl -v https://api.robinhood.com/watchlists/Default/bulk_add/ \
   -H "Accept: application/json" \
   -H "Authorization: Token a9a7007f890c790a30a0e0f0a7a07a0242354114" \
   -d symbols=MSFT,F,FB,RHT,FAKE
```

**Response**

Fields are returned as a list of hashes which contain the following for each added symbol:

| Key        | Type     | Description |
|------------|----------|-------------|
| watchlist  | URL      | Link to the watchlist you just added the instrument to   |
| instrument | URL      | Link to the instrument itself                            |
| created_at | ISO 8601 | Timestamp when the instrument was added to the watchlist |
| url        | URL      | Link to this instrument as a member of this watchlist    |

** Response sample**
```
[{
    "watchlist": "https://api.robinhood.com/watchlists/Default/",
    "instrument": "https://api.robinhood.com/instruments/50810c35-d215-4866-9758-0ada4ac79ffa/",
    "created_at": "2016-02-09T00:15:20.103927Z",
    "url": "https://api.robinhood.com/watchlists/Default/50810c35-d215-4866-9758-0ada4ac79ffa/"
}, {
    "watchlist": "https://api.robinhood.com/watchlists/Default/",
    "instrument": "https://api.robinhood.com/instruments/6df56bd0-0bf2-44ab-8875-f94fd8526942/",
    "created_at": "2016-02-09T00:15:20.103927Z",
    "url": "https://api.robinhood.com/watchlists/Default/6df56bd0-0bf2-44ab-8875-f94fd8526942/"
}, {
    "watchlist": "https://api.robinhood.com/watchlists/Default/",
    "instrument": "https://api.robinhood.com/instruments/ebab2398-028d-4939-9f1d-13bf38f81c50/",
    "created_at": "2016-02-09T00:15:20.103927Z",
    "url": "https://api.robinhood.com/watchlists/Default/ebab2398-028d-4939-9f1d-13bf38f81c50/"
}, {
    "watchlist": "https://api.robinhood.com/watchlists/Default/",
    "instrument": "https://api.robinhood.com/instruments/73f0b448-ac9c-49c6-b281-ef28aa51fd3f/",
    "created_at": "2016-02-09T00:15:20.103927Z",
    "url": "https://api.robinhood.com/watchlists/Default/73f0b448-ac9c-49c6-b281-ef28aa51fd3f/"
}]
```

#### Create watchlist

So, you need to keep track of a few securites? Here's how.

**Method**

| URI                           | HTTP Method | Authentication |
|-------------------------------|-------------|----------------|
| api.robinhood.com/watchlists/ | POST        | *Yes*          |

**Fields**

| Parameter | Type   | Description                                          | Default |Required|
|-----------|--------|------------------------------------------------------|---------|--------|
| name      | String | Alphanumeric name for this watchlist (A-B,a-b,0-9,_) | N/A     | *Yes*  |

**Request sample**

```
curl -v https://api.robinhood.com/watchlists/ \
   -H "Accept: application/json" \
   -H "Authorization: Token a9a7007f890c790a30a0e0f0a7a07a0242354114" \
   -d name=Technology
```

**Response**

Fields are returned as a hash with the following keys:

| Key  | Type   | Description |
|------|--------|-------------|
| url  | URL    | Link to this watchlist     |
| user | String | Link back to the user page |
| name | String | The name you used above    |

** Response sample**
```
{
	"url": "https://api.robinhood.com/watchlists/Technology/",
    "user": "https://api.robinhood.com/user/",
    "name": "Technology"
}
```

#### TODO
	- Get Watchlist instruments		GET /watchlists/$watchlistName/?cursor=$cursor
	- Add instrument to watchlist	POST /watchlists/$instrumentId/
	- Get Watchlists				GET /watchlists/
	- Delete Instrument				DELETE /watchlists/$watchlistName/$instrumentId/
	- Reorder Watchlist				POST /watchlists/$watchlistName/reorder/	{ids}

### Instruments
#### TODO
	- Query Instruments				GET /instruments/?query=$query
	- Get Fundamental Info			GET /fundamentals/$symbol/

### Application Information
#### TODO
	- Get Config Vitals				GET /midlands/conficurations/vitals/android/

### Quotes

The `/quotes` relative path is a directory that contains information relevant current and historical data on a particular security. It has the `historicals` sub-directory which is described below.

**Notes**

* Quotes are provided by Robinhood without requiring login information.

#### Gather Quote Data by Ticker Symbol



`/quotes/{symbol}/`

This subdirectory retrieves current quote data about a particular security traded with the given `{symbol}`.

Data is returned as a JSON structure and looks like this call to `https://api.robinhood.com/quotes/MSFT/`:

    { "ask_price": "54.2100",
      "ask_size": 2000,
      "bid_price": "54.2000",
      "bid_size": 1800,
      "last_trade_price": "54.1900",
      "last_extended_hours_trade_price": null,
      "previous_close": "54.6600",
      "adjusted_previous_close" : "54.6600",
      "previous_close_date": "2016-03-17",
      "symbol": "MSFT",
      "trading_halted": false,
      "updated_at": "2016-03-18T15:45:28Z"
    }

#### Gather Quote Data for Multiple Ticker Symbols in a Single API Call

`/quotes/?symbols=...`

You can gather quote data for a list of symbols at once by handing the bare `/quotes` path a `symbols` query filled with comma separated symbols.

Returned data is semi-paginated (in that there are no `next` or `previous` keys) and looks a lot like this call to `https://api.robinhood.com/quotes/?symbols=MSFT,FB,TSLA`.

    { "results": [{
            "ask_price": "54.1100",
            "ask_size": 1200,
            "bid_price": "54.1000",
            "bid_size": 3000,
            "last_trade_price": "54.0400",
            "last_extended_hours_trade_price": null,
            "previous_close": "54.6600",
            "adjusted_previous_close": "54.6600",
            "previous_close_date": "2016-03-17",
            "symbol": "MSFT",
            "trading_halted": false,
            "updated_at": "2016-03-18T16:16:48Z"
        }, {
            "ask_price": "111.8900",
            "ask_size": 600,
            "bid_price": "111.8800",
            "bid_size": 200,
            "last_trade_price": "112.1500",
            "last_extended_hours_trade_price": null,
            "previous_close": "111.0200",
            "adjusted_previous_close": "111.0200",
            "previous_close_date": "2016-03-17",
            "symbol": "FB",
            "trading_halted": false,
            "updated_at": "2016-03-18T16:16:52Z"
        }, {
            "ask_price": "231.8900",
            "ask_size": 100,
            "bid_price": "231.7600",
            "bid_size": 100,
            "last_trade_price": "231.9867",
            "last_extended_hours_trade_price": null,
            "previous_close": "226.3800",
            "adjusted_previous_close": "226.3800",
            "previous_close_date": "2016-03-17",
            "symbol": "TSLA",
            "trading_halted": false,
            "updated_at": "2016-03-18T16:16:43Z"
        }]
    }

#### TODO
	- Get Historical Quotes			GET /quotes/historicals/$symbol/?interval=$i&span=$s
																		{interval=5minute|10minute (required)
																		 span=week|day|
	- Get Quotes					GET /quotes/?[symbols=$csv_symbols][&cursor=$cursor]

## Pagination

Some data is returned from the Robinhood API as paginated data with `next` and `previous` cursors already in URL form.

If your call returns paginated data, it will look like this call to `https://api.robinhood.com/instruments/`:

```
{
    "previous": null,
    "results": [{
        "splits" : "https://api.robinhood.com/instruments/42e07e3a-ca7a-4abc-8c23-de49cb657c62/splits/",
        "margin_initial_ratio" : "1.0000",
        "url" : "https://api.robinhood.com/instruments/42e07e3a-ca7a-4abc-8c23-de49cb657c62/",
        "quote" : "https://api.robinhood.com/quotes/SBPH/",
        "symbol" : "SBPH",
        "bloomberg_unique" : "EQ0000000028928752",
        "list_date" : null,
        "fundamentals" : "https://api.robinhood.com/fundamentals/SBPH/",
        "state" : "active",
        "tradeable" : true,
        "maintenance_ratio" : "1.0000",
        "id" : "42e07e3a-ca7a-4abc-8c23-de49cb657c62",
        "market" : "https://api.robinhood.com/markets/XNAS/",
        "name" : "Spring Bank Pharmaceuticals, Inc. Common Stock"
    },
        ...
    ],
    "next": "https://api.robinhood.com/instruments/?cursor=cD04NjUz"
}
```

To get the next page of results, just use the `next` URL.

### Semi-Pagination

Some data is returned as a list of `results` as if they were paginate but the API doesn't supply us with `previous` or `next` keys.

## Version Information and Major Changes

I'll list anything major here by date and Robinhood API version as reported by the server.

v0.001 - April xx, 2016 (1.69.3)
   - First version
