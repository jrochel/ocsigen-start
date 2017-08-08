(* Ocsigen-start
 * http://www.ocsigen.org/ocsigen-start
 *
 * Copyright (C) Université Paris Diderot, CNRS, INRIA, Be Sport.
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation, with linking exception;
 * either version 2.1 of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
 *)

let%client reload () =
  Eliom_client.change_page ~service:Eliom_service.reload_action_hidden () ()

let%shared memoizator f =
  let value_ref = ref None in
  fun () ->
    match !value_ref with
    | Some value -> Lwt.return value
    | None ->
      let%lwt value = f () in
      value_ref := Some value;
      Lwt.return value

let%shared string_repeat s n =
  let b = Buffer.create (n * (String.length s)) in
  let rec f i =
    if i < n then begin
      Buffer.add_string b s;
      f (i + 1)
    end else
      Buffer.contents b
  in
  f 0

let%shared string_filter f s =
  let b = Buffer.create (String.length s) in
  String.iter (fun c -> if f c then Buffer.add_char b c) s;
  Buffer.contents b

let%shared email_regexp =
  Re_str.regexp "[^@].*@[^.].*\\.[^.]+$"

let%shared phone_regexp =
  Re_str.regexp ("\\+" ^ string_repeat "[0-9] *" 7 ^ "[0-9 ]*$")

[%%shared.start]

module Email_or_phone = struct

  type y = [`Email | `Phone]
  [@@deriving json]

  type t = string * y [@@deriving json]

  let to_string = fst

  let y = snd

  module Almost = struct

    type nonrec y = [ y | `Almost_phone | `Almost_email | `Invalid ]
    [@@deriving json]

    type t = string * y [@@deriving json]

    let to_string = fst

    let y = snd

    let almost_email s =
      try
        ignore (String.index s '@');
        true
      with Not_found ->
        false

    let almost_phone =
      let r = Re_str.regexp "[0-9] *[0-9] *[0-9]" in
      fun s ->
        try
          ignore (Re_str.search_forward r s 0);
          true
        with Not_found ->
          false

    let of_string ~only_mail s =
      if Re_str.string_match email_regexp s 0 then
        s, `Email
      else if only_mail || almost_email s then
        (* We guess that the user intended to provide an e-mail; we
           will handle this with appropriate messages *)
        s, `Almost_email
      else if Re_str.string_match phone_regexp s 0 then
        string_filter ((<>) ' ') s, `Phone
      else if almost_phone s then
        s, `Almost_phone
      else
        s, `Invalid

  end

  let of_almost = function
    | s, (`Invalid | `Almost_email | `Almost_phone) ->
      None
    | s, ((`Email | `Phone) as y) ->
      Some (s, y)

  let of_string ~only_mail s = of_almost (Almost.of_string ~only_mail s)

end

let%client on_enter ~f inp =
  Lwt.async @@ fun () ->
  Lwt_js_events.keydowns inp @@ fun ev _ ->
  if ev##.keyCode = 13 then
    f (Js.to_string inp##.value)
  else
    Lwt.return_unit

(* TODO: Build a nice Ot_form module with such functions *)
let%shared lwt_bind_input_enter
    ?(validate : (string -> bool) Eliom_client_value.t option)
    ?button
    (e : Html_types.input Eliom_content.Html.elt)
    (f : (string -> unit Lwt.t) Eliom_client_value.t) =
  ignore [%client (begin
    let e = Eliom_content.Html.To_dom.of_input ~%e in
    let f =
      let f = ~%(f : (string -> unit Lwt.t) Eliom_client_value.t) in
      match ~%validate with
      | Some validate ->
        fun v ->
          if validate v then
            e##.classList##remove(Js.string "invalid")
          else
            e##.classList##add(Js.string "invalid");
          f v
      | None ->
        f
    in
    on_enter ~f e;
    match
      ~%(button : [< Html_types.button | Html_types.input ]
             Eliom_content.Html.elt option)
    with
    | Some button ->
      Lwt.async @@ fun () ->
      Lwt_js_events.clicks (Eliom_content.Html.To_dom.of_element button)
      @@ fun _ _ -> f (Js.to_string e##.value)
    | None ->
      ()
  end : unit)]

let%shared lwt_bound_input_enter ?(a = []) ?button ?validate f =
  let e = Eliom_content.Html.D.Raw.input ~a () in
  lwt_bind_input_enter ?button ?validate e f;
  e

let%client bind_popup ?(button_label = "OK") f =
  let content close =
    let open Eliom_content.Html in
    let button =
      D.button ~a:[D.a_class ["button"]]
        [D.pcdata button_label]
    in
    let inp =
      let f code = let%lwt () = close () in f code in
      lwt_bound_input_enter ~button f
    in
    Lwt.return (D.div [ button ; inp ])
  in
  let%lwt _ =
    Ot_popup.popup
      ~close_button:[ Os_icons.F.close () ]
      ~onclose:(fun () ->
        Eliom_client.change_page
          ~service:Eliom_service.reload_action
          () ())
      content
  in
  Lwt.return_unit

[%%server.start]

module Http =
  struct
    let string_of_stream ?(len=16384) contents =
      Lwt.try_bind
        (fun () ->
           Ocsigen_stream.string_of_stream len (Ocsigen_stream.get contents))
        (fun r ->
           let%lwt () = Ocsigen_stream.finalize contents `Success in
           Lwt.return r)
        (fun e ->
           let%lwt () = Ocsigen_stream.finalize contents `Failure in
           Lwt.fail e)
  end
