# New chat

**User:** Anonymous  
**Created:** 10/9/2026 14:47:26  
**Updated:** 10/9/2026 14:47:43  
**Exported:** 10/9/2026 14:47:49  
**Link:** [https://chatgpt.com/c/6ac8d44d-5578-83ed-ba48-589814acfdaf?temporary-chat=true](https://chatgpt.com/c/6ac8d44d-5578-83ed-ba48-589814acfdaf?temporary-chat=true)  

## Prompt:
09.10.2026, 14:47:32

Each reservation has an id and a customer. It is pending, with the requested time; confirmed, with a
machine and one or more consecutive time slots; cancelled, either by the staff, who always give a reason,
or by the customer, who is refunded in full when cancelling at least two hours ahead and not at all
otherwise; or completed, with the machine and the length of the cycle in minutes.
{"id": 7, "customer": "anna", "status": "pending", "requested": "2026-10-14T18:00"}
{"id": 8, "customer": "boris", "status": "confirmed", "machine": "W2",
"slots": ["2026-10-14T19:00", "2026-10-14T19:30"]}
{"id": 9, "customer": "anna", "status": "cancelled", "cancelledBy": "staff", "reason": "machine out of order"}
{"id": 10, "customer": "dmitry", "status": "completed", "machine": "W1", "minutes": 52}
{"id": 11, "customer": "boris", "status": "cancelled", "cancelledBy": "customer", "refunded": true}
{"id": 12, "customer": "elena", "status": "cancelled", "cancelledBy": "customer", "refunded": false}
Give an assistant the description, the examples, and this request:
Model this data in Haskell, as plain data types without any JSON library. Then write machineLoad,
the total minutes of the completed cycles on a given machine, and staffReasons, the reasons of
all the cancellations by the staff.

## Response:
09.10.2026, 14:47:35 · gpt-6

A good Haskell model uses algebraic data types to represent the reservation status, with separate constructors for each status and its associated fields. `Maybe` is unnecessary because each constructor carries exactly the fields relevant to that status.

## Haskell data types

The timestamps are represented as `String` to avoid requiring a date/time library. The refund flag records whether the customer received a full refund.

```haskell
data Reservation = Reservation
  { reservationId :: Int
  , customer      :: String
  , status        :: Status
  } deriving (Show)

data Status
  = Pending String
  | Confirmed String [String]
  | Cancelled Cancellation
  | Completed String Int
  deriving (Show)

data Cancellation
  = Staff String
  | Customer Bool
  deriving (Show)

examples :: [Reservation]
examples =
  [ Reservation 7 "anna"
      (Pending "2026-10-14T18:00")

  , Reservation 8 "boris"
      (Confirmed "W2"
        ["2026-10-14T19:00", "2026-10-14T19:30"])

  , Reservation 9 "anna"
      (Cancelled (Staff "machine out of order"))

  , Reservation 10 "dmitry"
      (Completed "W1" 52)

  , Reservation 11 "boris"
      (Cancelled (Customer True))

  , Reservation 12 "elena"
      (Cancelled (Customer False))
  ]
```

## `machineLoad`

Calculate the total minutes of completed cycles on a given machine:

```haskell
machineLoad :: String -> [Reservation] -> Int
machineLoad machine reservations =
  sum [minutes |
       Reservation _ _ (Completed m minutes) <- reservations,
       m == machine]
```

Example:

```haskell
machineLoad "W1" examples
-- 52
```

## `staffReasons`

Collect the reasons for all cancellations performed by staff:

```haskell
staffReasons :: [Reservation] -> [String]
staffReasons reservations =
  [reason |
   Reservation _ _ (Cancelled (Staff reason)) <- reservations]
```

Example:

```haskell
staffReasons examples
-- ["machine out of order"]
```

## Modeling choices

- **Pending:** stores the requested time.
- **Confirmed:** stores the machine and a list of consecutive time slots.
- **Cancelled:** distinguishes staff cancellations, which require a reason, from customer cancellations, which record the refund outcome.
- **Completed:** stores the machine and cycle duration in minutes.

This representation makes invalid combinations harder to express. For example, a pending reservation cannot accidentally carry a completed cycle's duration, and a staff cancellation cannot omit its reason.



---
Powered by [ChatGPT Exporter](https://www.chatgptexporter.com)