;; Define Data Variables
(define-data-var proposal-count uint u0)

;; Define Data Maps
(define-map proposals
    uint 
    {
        title: (string-utf8 256),
        description: (string-utf8 1024),
        creator: principal,
        votes-for: uint,
        votes-against: uint,
        end-block-height: uint,
        executed: bool
    }
)

(define-map votes
    {proposal-id: uint, voter: principal}
    {voted: bool, support: bool}
)

;; Error constants
(define-constant ERR-NOT-FOUND (err u404))
(define-constant ERR-ALREADY-VOTED (err u401))
(define-constant ERR-VOTING-CLOSED (err u402))
(define-constant ERR-NOT-EXECUTED (err u403))

;; Create a new proposal
(define-public (create-proposal (title (string-utf8 256)) (description (string-utf8 1024)) (voting-period uint))
    (let
        (
            (proposal-id (var-get proposal-count))
            (end-height (+ block-height voting-period))
        )
        (map-set proposals proposal-id {
            title: title,
            description: description,
            creator: tx-sender,
            votes-for: u0,
            votes-against: u0,
            end-block-height: end-height,
            executed: false
        })
        (var-set proposal-count (+ proposal-id u1))
        (ok proposal-id)
    )
)

;; Cast a vote on a proposal
(define-public (cast-vote (proposal-id uint) (support bool))
    (let
        (
            (proposal (unwrap! (map-get? proposals proposal-id) ERR-NOT-FOUND))
            (vote-record (map-get? votes {proposal-id: proposal-id, voter: tx-sender}))
        )
        (asserts! (< block-height (get end-block-height proposal)) ERR-VOTING-CLOSED)
        (asserts! (is-none vote-record) ERR-ALREADY-VOTED)
        
        (map-set votes {proposal-id: proposal-id, voter: tx-sender} {voted: true, support: support})
        
        (if support
            (map-set proposals proposal-id 
                (merge proposal {votes-for: (+ (get votes-for proposal) u1)}))
            (map-set proposals proposal-id 
                (merge proposal {votes-against: (+ (get votes-against proposal) u1)}))
        )
        (ok true)
    )
)

;; Get proposal details
(define-read-only (get-proposal (proposal-id uint))
    (ok (unwrap! (map-get? proposals proposal-id) ERR-NOT-FOUND))
)

;; Check if an account has voted on a proposal
(define-read-only (has-voted (proposal-id uint) (account principal))
    (let ((vote (map-get? votes {proposal-id: proposal-id, voter: account})))
        (if (is-some vote)
            (ok true)
            (ok false)
        )
    )
)

;; Get total proposals count
(define-read-only (get-proposal-count)
    (ok (var-get proposal-count))
)
