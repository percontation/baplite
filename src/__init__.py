import logging

from .baplite_stubs import lift_stub
import bap.bil as bil

logger = logging.getLogger(__name__)

def lift(arch, addr, code):
  """Lifts bytes into BIL ADT

  Arguments:
    arch (str): Architecture to lift the bytes for. Any BAP recognizable
                  string like 'i386', 'x86-64', or 'arm' works.
    addr (int): Address of the instructions being lifted.
    code (str): Byte data to lift.

  Returns:
    A list of bap.bil.Stmt, or None if lifting fails.
  """
  try:
    ocaml_output = lift_stub(arch, addr, code)
    if ocaml_output.startswith('['):
      try:
        return eval(ocaml_output, bil.__dict__)
      except KeyboardInterrupt:
        raise
      except BaseException:
        logger.exception("Error while evaling ocaml output")
        return None
    else:
      if 'unimplemented feature' in ocaml_output or 'opcode unsupported' in ocaml_output:
        lvl = logging.DEBUG
      else:
        lvl = logging.WARNING

      if len(code) > 40:
        ellip = '...'
        errbytes = code[:40]
      else:
        ellip = ''
        errbytes = code

      logger.log(lvl, "Could not lift BIL for bytes %r%s: %s", errbytes, ellip, ocaml_output)
      return None
  except Exception:
    logger.exception("Error while lifting")
    return None

__all__ = ['lift', 'bil']
