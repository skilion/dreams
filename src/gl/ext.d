module gl.ext;

import core.stdc.string;
import cstr;
import log;

/*
  Search ext in exts.
  ext and exts must be null terminated strings
*/
bool isExtPresent(const(char)* ext, const(char)* exts) nothrow
{
	if (ext && exts)
	{
		auto length = strlen(ext);
		exts = strstr(exts, ext);
		while(exts)
		{
			if (exts[length] == ' ' || exts[length] == '\0')
			{
				return true;
			}
			exts = strstr(exts + length, ext);
		}
	}
	return false;
}
