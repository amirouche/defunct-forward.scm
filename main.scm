(pk "* start of main.scm")

(define container (document-query-selector "#root"))

(define (init)
  0)

(define (button-clicked model spawn)
  (lambda (event)
    (+ 1 model)))

(define (view model mc)
  (pk model)
  `(div (@ (id . "root"))
        (div (@ (id . "container"))
             (h1 "forward.scm " (small "⋅ frontend framework for Scheme"))
             (h2 "Example")
             (p "The counter has a value of " ,model)
             (p (button (@ (on . ((click . ,(mc button-clicked))))) "increment"))
             (h2 "Introduction")
             (p "forward.scm is a library that allows to code
                dynamic website using the scheme language.")
             (p "This website is written using forward.scm")
             (p "To quickly get started clone the git repository:")
             (pre "> git clone https://github.com/amirouche/forward.scm")
             (p "To know more continue reading")
             (h2 "Kesako ?!")
             (p "forward.scm is frontend framework that follows
                the " (a (@ (href . "https://en.wikipedia.org/wiki/Model-view-controller"))
                         "Model-View-Controller pattern")
                " (MVC) that use Scheme (I hope you already understood that
                (anyway if you are not a schemers there is little chance
                you will be reading this (otherwise welcome!)))")
             (p "MVC is well known pattern used in graphical user interface
                 where basically a graphical application is split into 3 
                 pieces:")
             (ul (li "Model is the data. In forward.scm there is single 
                      immutable model datastructure that is built out of
                      lists (more likely association lists). It is not a global
                      or fluid per se, it's passed around and through the
                      magic of closures (you do no need to understand what
                      closures are to use forward.scm)")
                 (li "View is... well the user interface per se. The piece
                      of code that represent the objects you see. In forward.scm
                      this is coded using a sxml (a scheme DSL for writting 
                      html or xml (where attributes are pure association list)).
                      In forward, there is a single view that in turns can use
                      sub views. At the very core, there is a single view.")
                 (li "Controllers are the procedure where the logic of the 
                      application lives. Otherwise said everything that is not
                      view or model. Most of the time in graphical user interfaces,
                      controllers are event handlers. It is not always the case
                      but it's the most common kind of controller"))
             (p "With this small introduction to MVC you already know a lot about
                 forward.scm. First there is single model, there is a single view
                 which use sxml to represent the user interface and there are
                 controllers which are most of the time event handlers.")
             (p "(Most advanced MVC users might wonder whether it's possible to 
                 compose hierarchically components, the answer is yes!)")
             (h2 "Widgets")
             (p "FIXME")
             (h2 "Reference API")
             (h3 "(create-app container init view)")
             (p "forward.js comes with various scheme helpers and javascript bindings,
                 but the very core of it, the thing that is really revolutionary is
                 the create-app procedure.")
             (p "It takes a CONTAINER as first argument, this should be a DOM node that
                 will be replaced by the what return the VIEW procedure.")
             (p "The second argument is INIT a procedure that must return the initial
                 model of the app. It's the seed of the model. It will be passed around
                 the app in VIEW and in controllers that you will write yourself. INIT
                 doesn't take any arguments.")
             (p "The last argument is VIEW. It's a procedure that takes two arguments.
                 It looks like the following:")
             (pre "(define (view model mc)
  `(div (@ (id . \"root\"))
     \"Héllo world!\"))")
             (p "VIEW takes the current model as first arguments and a second procedure
                 called mc for short (its real name is make-controller). That mc takes
                 procedure as first and only argument and return basically a procedure
                 that is bound to the current model. The VIEW must return sxml data with
                 event handlers bound to DOM events inside the 'on attributes of sxml
                 nodes. Ready?")
             (h4 "Example")
             (p "It will be more clear with a simple example. Imagine a clicker game
                 where the only purpose is to click buttons to increase counters. Have
                 that in mind? Yeah, then in that counters app the init procedure can
                 look like the following:")
             (pre "(define (init) 0)")
             (p "The initial model is ZERO!")
             (p "The view looks like the following:")
             (pre "(define (view model mc)
  `(div
     (p \"The counter has a value of \" ,model)
     (p (button (@ (on . ((click . ,(mc button-clicked))))) \"increment\"))))")
             (p "As you can see that sxml file reference a button-clicked procedure
                 that is not defined yet. Its definition follows:")
             (pre "(define (button-clicked model spawn)
  (lambda (event)
    (+ 1 model)))"))))


(create-app container init view)
