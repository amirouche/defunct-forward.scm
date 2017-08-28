;; scheme helpers

(define (pk . args)
  (apply console-log (cons ";;;" args))
  (car (reverse args)))

(define (acons a b alist)
  (cons (cons a b) alist))

(define (rm alist key)
  (let loop ((alist alist)
             (out '()))
    (if (null? alist)
        out
        (if (equal? (caar alist) key)
            (append out (cdr alist))
            (loop (cdr alist) (cons (car alist) out))))))

(define (set alist key value)
  (acons key value (rm alist key)))

(define (ref alist key)
  (let loop ((alist alist))
    (cond
     ((null? alist) #f)
     ((equal? (caar alist) key) (cdar alist))
     (else (loop (cdr alist))))))

(define (ref* assoc . keys)
  (let loop ((keys keys)
             (assoc assoc))
    (cond
     ((eq? assoc #f) #f)
     ((null? keys) assoc)
     (else (loop (cdr keys) (ref assoc (car keys)))))))

(define (set* assoc . args)
  (let* ((args* (reverse args))
         (value (car args*))
         (keys (reverse (cdr args*))))
    (let loop ((keys keys)
               (assoc assoc))
      (if (null? keys)
          value
          (set assoc (car keys) (loop (cdr keys) (or (ref assoc (car keys)) '())))))))

(define (rm* assoc . keys)
  (if (null? (cdr keys))
      (rm assoc (car keys))
      (let ((new (apply rm* (ref assoc (car keys)) (cdr keys))))
        (if (null? new)
            (rm assoc (car keys))
            (set assoc (car keys) new)))))

(define (string-prefix? prefix string)
  (let ((l (string-length prefix)))
    (if (< (string-length string) l)
        #f
        (let ((other (substring string 0 l)))
          (equal? other prefix)))))

;;; async ajax bindings

(define $ (js-eval "jQuery"))

(define (ajax url settings k)
  (let ((promise (js-invoke $ "ajax" url (alist->js-obj settings))))
    (js-invoke promise "always" (js-closure k))))

;;; localStorage bindings

(define local-storage (js-eval "localStorage"))

(define (local-storage-set! key value)
  (js-invoke local-storage "setItem" key value))

(define (local-storage-ref key)
  (js-invoke local-storage "getItem" key))

;;; DOM bindings

(define %document (js-eval "document"))

(define (document-query-selector selector)
  (js-invoke %document "querySelector" selector))

(define (document-location-pathname)
  (js-ref (js-ref %document "location") "pathname"))

(define (document-dispatch-event name)
  (let ((event (js-invoke %document "createEvent" "Event")))
    (js-invoke event "initEvent" name #t #t)
    (js-invoke %document "dispatchEvent" event)))

(define (document-add-event-listener name proc)
  (js-invoke %document "addEventListener" name (js-closure proc) #f))

;; history API

(define %history (js-eval "history"))

(define (history-append url)
  (js-invoke %history "pushState" (alist->js-obj '()) "" url))

;;; snabbdom bindings

(define %window (js-eval "window"))

(define (patch old new)
  (js-invoke %window "patch" old new)
  new)

(define (html tag events children)
  (js-invoke %window "h" tag events (list->js-array children)))

;;; FIXME: use biwascheme bindings

(define (event-target event)
  (js-ref event "target"))

(define (event-target-value event)
  (js-ref (event-target event) "value"))

(define (event-target-checked event)
  (js-ref (event-target event) "checked"))

(define (event-key event)
  (js-ref event "key"))

(define (event-delta-y event)
  (js-ref event "deltaY"))

(define (event-prevent-default event)
  (js-invoke event "preventDefault"))

(define (set-timeout proc timeout)
  (js-invoke %window "setTimeout" (js-closure proc) timeout))

(define (attrs->js-obj alist)
  (alist->js-obj (map (lambda (pair)
                        (cons (symbol->string (car pair)) (cdr pair))) alist)))

(define (style->js-obj alist)
  (let ((out (rm (rm style 'remove) 'delayed)))
    (when (ref style 'remove)
      (set! out (acons "remove" (alist->js-obj (ref alist 'remove)) out)))
    (when (ref style 'delayed)
      (set! out (acons "delayed" (alist->js-obj (ref alist 'delayed)) out)))
    (attrs->js-obj out)))

(define (@->js-obj alist)
  (let ((out `(("attrs" . ,(attrs->js-obj (rm (rm alist 'on) 'style))))))
    (when (ref alist 'on)
      (set! out (acons "on" (attrs->js-obj (ref alist 'on)) out)))
    (when (ref alist 'style)
      (set! out (acons "style" (style->js-obj (ref alist 'style)) out)))
    (alist->js-obj out)))

(define (flatten lst)
  (let loop ((lst lst)
             (out '()))
    (cond
     ((null? lst) (reverse out))
     ((and (pair? (car lst)) (not (symbol? (caar lst)))) (loop (append (car lst) (cdr lst)) out))
     (else (loop (cdr lst) (cons (car lst) out))))))

(define (sxml->h element)
  (cond
   ((null? element) '())
   ((string? element) element)
   ((number? element) element)
   (else
    (let ((tag (symbol->string (car element))))
      (let ((attrs (cadr element)))
        (if (and (pair? attrs) (eq? (car attrs) '@))
            (html tag
                  (@->js-obj (cdr attrs))
                  (map sxml->h (flatten (cddr element))))
            (html tag
                  (alist->js-obj '())
                  (map sxml->h (flatten (cdr element))))))))))


(define (%create-app container init view)
  ;; FIXME: docstring
  (let ((model (init)))  ;; init model
    ;; create a procedure that allows to create new green threads
    (letrec ((spawn (lambda (timeout proc args)
                      (set-timeout (lambda () (apply (proc model spawn) args)) timeout)))
             ;; lambda used to wrap event callback
             (make-controller (lambda (proc)
                                (js-closure
                                 (lambda args
                                   (let ((new (apply (proc model spawn) args)))
                                     (when new
                                       (set! model new)
                                       (render)))))))
             ;; rendering pipeline
             (render (lambda ()
                       (let ((sxml (view model make-controller)))
                         (set! container (patch container (sxml->h sxml)))))))

      ;; change procedure allows to sneak into the app closure
      (lambda (proc)
        (let ((new (proc model spawn)))
          (when new
            (set! model new)
            (render))))))) ;; render the new model

(define (create-app container init view)
  (let ((change (%create-app container init view)))
    (change (lambda (model spawn) model))
    change)) ;; trigger a render

;; router

(define (make-route route)
  (cons (cdr (string-split (car route) "/")) (cdr route)))

(define (component-match route url)
  (cond
   ((string-prefix? ":" route)
    (values #t (cons (substring route 0 (string-length route)) url)))
   ((equal? route url) (values #t '()))
   (else (values #f '()))))

(define (route-match route url)
  (let loop ((route route)
             (url url)
             (out '()))
    (cond
     ((and (null? route) (null? url)) (values #t out))
     ((or (null? route) (null? url)) (values #f '()))
     (else (call-with-values (lambda () (component-match (car route) (car url)))
             (lambda (match? params)
               (if match?
                   (loop (cdr route) (cdr url) (append params out))
                   (values #f '()))))))))

(define (change-unknown-route model)
  (set* (rm model 'location) 'location 'route 'unknown))

(define (change-location model route params)
  (set* (set* model 'location 'route route) 'location 'params params))

(define (resolve model spawn)
  (let ((url (car (make-route (cons (document-location-pathname) #f)))))
    (let loop ((routes (ref model '%routes)))
      (if (null? routes)
          (change-unknown-route model)
          (call-with-values (lambda () (route-match (caar routes) url))
            (lambda (match? params)
              (if match?
                  ((cdar routes) (change-location model (caar routes) params) spawn)
                  (loop (cdr routes)))))))))

(define (create-app* container init view routes) ;; create-app with router
  (let ((change (%create-app container init view))
        (routes (map make-route routes)))
    ;; set the routes in the model
    (change (lambda (model spawn) (set model '%routes routes)))
    ;; resolve when back button is clicked
    (document-add-event-listener "onpopstate" (lambda (event) (change resolve)))
    ;; initial resolution
    (change resolve)
    ;; return the change
    change))

(define (link-clicked url)
  (lambda (model spawn)
    (lambda (event)
      (event-prevent-default event)
      (history-append url)
      (resolve model spawn))))

(define (link mc url children)
  "Create a link to URL with CHILDREN as children"
  `(a (@ (href . ,url) (on . ((click . ,(mc (link-clicked url))))))
      ,children))

(define (identity-controller model spawn) model)
