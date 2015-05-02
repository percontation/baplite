#include <string.h>

#include <caml/memory.h>
#include <caml/mlvalues.h>
#include <caml/alloc.h>
#include <caml/callback.h>

#define PY_SSIZE_T_CLEAN
#include <python2.7/Python.h>

static value *ocaml_lift_stub = 0;

static void lift_stub(char *arch, char *code, size_t codelen,
                      uint64_t addr, char **bil, size_t *billen) {
	CAMLparam0();
	CAMLlocal4(oarch, ocode, oaddr, ores);

	size_t archlen = strlen(arch);
	oarch = caml_alloc_string(archlen);
	memcpy(String_val(oarch), arch, archlen);

	ocode = caml_alloc_string(codelen);
	memcpy(String_val(ocode), code, codelen);

	oaddr = caml_copy_int64(addr);

	ores = caml_callback3(*ocaml_lift_stub, oarch, oaddr, ocode);
	mlsize_t reslen = caml_string_length(ores);

	*bil = malloc(reslen);
	memcpy(*bil, String_val(ores), reslen);
	*billen = reslen;
	CAMLreturn0;
}

static PyObject *python_lift_stub(PyObject *self, PyObject *args) {
	char *arch;
	unsigned long long addr;
	char *code;
	Py_ssize_t len;
	if(!PyArg_ParseTuple(args, "sKs#", &arch, &addr, &code, &len)) return NULL;

	char *bil;
	size_t billen;
	lift_stub(arch, code, len, addr, &bil, &billen);

	PyObject *ret = Py_BuildValue("s#", bil, billen);
	free(bil);
	return ret;
}

static PyMethodDef PythonMethods[] = {
	{"lift_stub", python_lift_stub, METH_VARARGS,
		"lift_stub(arch, addr, bytes) -> string\n\n"
		"Get evalable BIL string for one instruction of the input bytes,\n"
		"or a string that evals to an Exception object."},
	{NULL, NULL, 0, NULL}
};

PyMODINIT_FUNC initbaplite_stubs(void) {
	static char *argv[2] = {"baplite_stubs", NULL};
	caml_startup(argv);
	ocaml_lift_stub = caml_named_value("lift_stub");

	PyObject *m = Py_InitModule("baplite_stubs", PythonMethods);
	if(!m) return;
}
