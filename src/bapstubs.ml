open Core_kernel
open Core_kernel.Or_error
open Bap.Std

module Dis = Disasm_expert.Basic

exception No_lifter
exception No_instr
exception Disasm_fail of string
exception Lift_fail of string

let make_mem arch (addr, s) =
  Memory.create
    LittleEndian
    (Addr.of_int64 ~width:(Size.to_bits @@ Arch.addr_size arch) addr)
    (Bigstring.of_string s) |> ok_exn ;;

let get_disassembler =
  let memo = ref Arch.Map.empty in
  fun arch -> match Arch.Map.find !memo arch with
    | Some dis -> dis
    | None -> let dis = Dis.create ~backend:"llvm" (Arch.to_string arch) |> ok_exn in
              (memo := Arch.Map.add !memo arch dis; dis)

let get_lifter = function
  | #Arch.arm -> ARM.lift
  | `x86 -> IA32.lift
  | `x86_64 -> AMD64.lift
  | _ -> raise No_lifter

let lift arch (addr, s) =
  let mem = make_mem arch (addr, s) in
  match Dis.insn_of_mem (get_disassembler arch) mem with
    | Result.Error e -> raise @@ Disasm_fail (Error.to_string_hum e)
    | Result.Ok (_, None, _) -> raise No_instr
    | Result.Ok (_, Some insn, _) -> (
        match (get_lifter arch) mem insn with
          | Result.Ok bil -> bil
          | Result.Error e -> raise @@ Lift_fail (Error.to_string_hum e)
      )
;;

let lift_stub archstr addr s =
  try
    match Arch.of_string archstr with
      | Some arch -> lift arch (addr, s) |> Adt.strings_of_bil |> String.concat "," |> fun s -> "["^s^"]"
      | None -> "Invalid architecture"
  with
    | No_lifter -> "No lifter for that architecture."
    | No_instr -> "No instruction disassembled from bytes."
    | Disasm_fail s -> "Disassembly failed: " ^ s
    | Lift_fail s -> "Lifting failed: " ^ s
    | e -> "Unexpected failure: " ^ Printexc.to_string e

let () =
  Bap_plugins.Std.Plugins.load () ;
  Callback.register "lift_stub" lift_stub ;;
