module signals;

mixin template Signal(Params...)
{
	alias void delegate(Params) slot_t;
	private slot_t[] slots;

	final void connect(slot_t slot)
	{
		slots ~= slot;
	}

	final void disconnect(slot_t slot)
	{
		for (size_t i = 0; i < slots.length; i++)
		{
			if (slots[i] == slot)
			{
				slots[i] = slots[slots.length - 1];
				slots.length--;
				break;
			}
		}
	}

	final void emit(Params params)
	{
		foreach (slot; slots)
		{
			slot(params);
		}
	}
}

unittest
{
	struct Subject
	{
		mixin Signal!(int*);
	}

	struct Observer
	{
		void watch(int* i)
		{
			(*i)++;
		}
	}

	void watch(int* i)
	{
		(*i)++;
	}

	Subject s;
	Observer o;

	int value = 0;
	s.connect(&o.watch);
	s.connect(&watch);
	s.emit(&value);
	assert(value == 2);
}
