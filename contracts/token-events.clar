;; TokenSync Events Contract

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-unauthorized (err u100))

;; Events map
(define-map sync-events
  uint
  {
    token-id: uint,
    old-state: uint,
    new-state: uint,
    triggered-by: principal,
    timestamp: uint
  }
)

(define-data-var event-nonce uint u0)

;; Event logging
(define-public (log-sync-event (token-id uint) (old-state uint) (new-state uint))
  (let (
    (sender tx-sender)
    (event-id (var-get event-nonce))
  )
    (asserts! (contract-call? .token-sync get-token-info token-id) err-unauthorized)
    (map-set sync-events
      event-id
      {
        token-id: token-id,
        old-state: old-state, 
        new-state: new-state,
        triggered-by: sender,
        timestamp: block-height
      }
    )
    (var-set event-nonce (+ event-id u1))
    (ok event-id)
  )
)

;; Read only functions  
(define-read-only (get-event (event-id uint))
  (map-get? sync-events event-id)
)
