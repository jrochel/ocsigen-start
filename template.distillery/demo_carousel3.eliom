(* This file was generated by Ocsigen Start.
   Feel free to use it, modify it, and redistribute it as you wish. *)

(* Wheel demo *)

[%%shared
  open Eliom_content.Html
  open Eliom_content.Html.F
]

(* Service for this demo *)
let%server service =
  Eliom_service.create
    ~path:(Eliom_service.Path ["demo-carousel3"])
    ~meth:(Eliom_service.Get Eliom_parameter.unit)
    ()

(* Make service available on the client *)
let%client service = ~%service

(* Name for demo menu *)
let%shared name () = [%i18n S.demo_carousel_wheel]

(* Class for the page containing this demo (for internal use) *)
let%shared page_class = "os-page-demo-carousel3"

(* Page for this demo *)
let%shared page () =
  let carousel_pages =
    [ [%i18n S.monday] ^ " 1"
    ; [%i18n S.tuesday] ^ " 1"
    ; [%i18n S.wednesday] ^ " 1"
    ; [%i18n S.thursday] ^ " 1"
    ; [%i18n S.friday] ^ " 1"
    ; [%i18n S.saturday] ^ " 1"
    ; [%i18n S.sunday] ^ " 1"
    ; [%i18n S.monday] ^ " 2"
    ; [%i18n S.tuesday] ^ " 2"
    ; [%i18n S.wednesday] ^ " 2"
    ; [%i18n S.thursday] ^ " 2"
    ; [%i18n S.friday] ^ " 2"
    ; [%i18n S.saturday] ^ " 2"
    ; [%i18n S.sunday] ^ " 2"
    ; [%i18n S.monday] ^ " 3"
    ; [%i18n S.tuesday] ^ " 3"
    ; [%i18n S.wednesday] ^ " 3"
    ; [%i18n S.thursday] ^ " 3"
    ; [%i18n S.friday] ^ " 3"
    ; [%i18n S.saturday] ^ " 3"
    ; [%i18n S.sunday] ^ " 3"
    ; [%i18n S.monday] ^ " 4"
    ; [%i18n S.tuesday] ^ " 4"
    ; [%i18n S.wednesday] ^ " 4"
    ; [%i18n S.thursday] ^ " 4"
    ; [%i18n S.friday] ^ " 4"
    ; [%i18n S.saturday] ^ " 4"
    ; [%i18n S.sunday] ^ " 4"
    ; [%i18n S.monday] ^ " 5"
    ; [%i18n S.tuesday] ^ " 5"
    ; [%i18n S.wednesday] ^ " 5"
    ; [%i18n S.thursday] ^ " 5"
    ; [%i18n S.friday] ^ " 5"
    ; [%i18n S.saturday] ^ " 5"
    ; [%i18n S.sunday] ^ " 5" ]
  in
  let length = List.length carousel_pages in
  let carousel_content = List.map (fun p -> D.div [ pcdata p ]) carousel_pages
  in
  let carousel_change_signal =
    [%client (React.E.create () :
                ([ `Goto of int | `Next | `Prev ] as 'a) React.E.t
                * (?step:React.step -> 'a -> unit)) ]
  in
  let update = [%client fst ~%carousel_change_signal] in
  let change = [%client fun a -> (snd ~%carousel_change_signal ?step:None a) ]
  in
  let carousel, pos, _swipe_pos =
    Ot_carousel.wheel
      ~a:[ a_class ["demo-carousel3"] ]
      ~update
      ~vertical:true
      ~inertia:1.
      ~position:10
      ~transition_duration:3.
      ~face_size:25
      carousel_content
  in

  Lwt.return
    [ p [%i18n demo_carousel_third_example_1]
    ; carousel
    ; div [
        Ot_carousel.previous ~a:[ a_class ["demo-prev"] ] ~change ~pos [];
        Ot_carousel.next ~a:[ a_class ["demo-next"] ] ~change
          ~pos ~size:(Eliom_shared.React.S.const 1) ~length
          []
      ]
    ]
