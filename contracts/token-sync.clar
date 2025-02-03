;; TokenSync Contract

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-unauthorized (err u100))
(define-constant err-invalid-state (err u101))
(define-constant err-not-found (err u102))

;; Data structures
(define-map token-registry
  { token-id: uint }
  { 
    owner: principal,
    state: uint,
    last-update: uint,
    validators: (list 10 principal)
  }
)

(define-map validator-registry
  principal 
  { active: bool, weight: uint }
)

;; State management
(define-public (register-token (token-id uint))
  (let ((sender tx-sender))
    (asserts! (is-eq sender contract-owner) err-unauthorized)
    (ok (map-set token-registry
      { token-id: token-id }
      { 
        owner: sender,
        state: u0,
        last-update: block-height,
        validators: (list)
      }
    ))
  )
)

(define-public (update-state (token-id uint) (new-state uint))
  (let (
    (token (unwrap! (map-get? token-registry {token-id: token-id}) err-not-found))
    (sender tx-sender)
  )
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
(define-public (add-validator (token-id uint) (validator principal))
  (let (
    (token (unwrap! (map-get? token-registry {token-id: token-id}) err-not-found))
    (sender tx-sender)
  )
    (asserts! (is-eq sender (get owner token)) err-unauthorized)
    (ok (map-set token-registry
      { token-id: token-id }
      (merge token {
        validators: (append (get validators token) validator)
      })
    ))
  )
)

;; Helper functions
(define-private (is-authorized (caller principal) (token {owner: principal, state: uint, last-update: uint, validators: (list 10 principal)}))
  (or
    (is-eq caller (get owner token))
    (is-some (index-of (get validators token) caller))
  )
)

;; Read only functions
(define-read-only (get-token-info (token-id uint))
  (map-get? token-registry {token-id: token-id})
)
