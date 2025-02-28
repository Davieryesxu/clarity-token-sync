;; TokenSync Contract

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-unauthorized (err u100))
(define-constant err-invalid-state (err u101))
(define-constant err-not-found (err u102))
(define-constant err-max-validators (err u103))
(define-constant err-contract-paused (err u104))

;; Data variables
(define-data-var contract-paused bool false)

;; Data structures
(define-map token-registry
  { token-id: uint }
  { 
    owner: principal,
    state: uint,
    last-update: uint,
    validators: (list 10 principal),
    metadata: (optional (string-ascii 256)),
    total-weight: uint
  }
)

(define-map validator-registry
  principal 
  { active: bool, weight: uint }
)

;; Admin functions
(define-public (set-contract-pause (paused bool))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-unauthorized)
    (ok (var-set contract-paused paused))
  )
)

;; State management
(define-public (register-token (token-id uint) (metadata (optional (string-ascii 256))))
  (let ((sender tx-sender))
    (asserts! (is-eq sender contract-owner) err-unauthorized)
    (asserts! (not (var-get contract-paused)) err-contract-paused)
    (ok (map-set token-registry
      { token-id: token-id }
      { 
        owner: sender,
        state: u0,
        last-update: block-height,
        validators: (list),
        metadata: metadata,
        total-weight: u0
      }
    ))
  )
)

(define-public (update-state (token-id uint) (new-state uint))
  (let (
    (token (unwrap! (map-get? token-registry {token-id: token-id}) err-not-found))
    (sender tx-sender)
  )
    (asserts! (not (var-get contract-paused)) err-contract-paused)
    (asserts! (is-authorized sender token) err-unauthorized)
    (ok (map-set token-registry
      { token-id: token-id }
      (merge token { 
        state: new-state,
        last-update: block-height
      })
    ))
  )
)

;; Validator management  
(define-public (add-validator (token-id uint) (validator principal) (weight uint))
  (let (
    (token (unwrap! (map-get? token-registry {token-id: token-id}) err-not-found))
    (sender tx-sender)
  )
    (asserts! (not (var-get contract-paused)) err-contract-paused)
    (asserts! (is-eq sender (get owner token)) err-unauthorized)
    (asserts! (< (len (get validators token)) u10) err-max-validators)
    (ok (map-set token-registry
      { token-id: token-id }
      (merge token {
        validators: (append (get validators token) validator),
        total-weight: (+ (get total-weight token) weight)
      })
    ))
  )
)

;; Helper functions
(define-private (is-authorized (caller principal) (token {owner: principal, state: uint, last-update: uint, validators: (list 10 principal), metadata: (optional (string-ascii 256)), total-weight: uint}))
  (or
    (is-eq caller (get owner token))
    (is-some (index-of (get validators token) caller))
  )
)

;; Read only functions
(define-read-only (get-token-info (token-id uint))
  (map-get? token-registry {token-id: token-id})
)

(define-read-only (is-paused)
  (var-get contract-paused)
)
