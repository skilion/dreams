import core.stdc.string: strlen;
import core.stdc.stdio: sprintf;

// converts a c string to a d string without extra memory allocations
auto cstr2dstr(inout(char)* cstr) nothrow
{
	return cstr ? cstr[0 .. strlen(cstr)] : cstr[0 .. 0];
}

// converts an integer to a d string without extra memory allocations
const(char)[] itoa(int n) nothrow
{
	static char[16] s;
	sprintf(s.ptr, "%d", n);
	return cstr2dstr(s.ptr);
}
