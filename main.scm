(pk "* start of main.scm")

(define container (document-query-selector "#root"))

(define (init)
  'hide)

(define (display-modal model spawn)
  (lambda (event)
    (pk 'display-modal)
    'show))

(define (close-modal model spawn)
  (lambda (event)
    (pk 'close-modal)
    'hide))

(define (show-event model spawn)
  (lambda (event)
    (pk event)
    model))

(define (view model mc)
  (pk 'view)
  `(div (@ (id . "root")
           (on . ((keypress . ,(mc show-event))))) ;; XXX: this doesn't work
        (h1 "bug 1: modal doesn't capture key events")
        (button (@ (on . ((click . ,(mc display-modal))))) "display modal")
        (p "The following input text demonstrates that keypress events are correctly
handled by input text")
        (input (@ (type . "text")
                  (placeholder . "open debugger and type something in here")
                  (on . ((keypress . ,(mc show-event))))))
        ,(if (eq? model 'show)
             `(div (@ (id . "modal")
                      (on . ((keypress . ,(mc close-modal))))) ;; XXX: this doesn't work
                   (div (@ (id . "modal-body"))
                        (h2 "This is a modal")
                        (button (@ (on . ((click . ,(mc close-modal))))) "close")
                        (p "This should disappear when ECHAP is pressed")))
             '(div ""))))


(create-app container init view)
