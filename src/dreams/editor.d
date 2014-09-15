module dreams.editor;

import dreams.world;

final class Editor
{
	private struct Action {
		uint[3] min, max;
		WorldBlock[] blocks;
	}

	private WorldNode* root;
	private Action[] undoActions, redoActions;
	private uint[3] clipboardSize;
	private WorldBlock[] clipboard;

	this(WorldNode* root)
	{
		assert(root);
		this.root = root;
	}

	void edit(const ref uint[3] min, const ref uint[3] max, WorldBlock block)
	{
		undoActions ~= backup(min, max);
		for (uint x = min[0]; x < max[0]; x++) {
			for (uint y = min[1]; y < max[1]; y++) {
				for (uint z = min[2]; z < max[2]; z++) {
					root.insertBlock(block, x, y, z);
				}
			}
		}
	}

	void copy(const ref uint[3] min, const ref uint[3] max)
	{
		clipboardSize = max;
		clipboardSize[] -= min[];
		read(min, max, clipboard);
	}

	void paste(const ref uint[3] pos)
	{
		uint[3] max = clipboardSize;
		max[] += pos[];
		write(pos, max, clipboard);
	}

	void undo()
	{
		if (undoActions.length > 0) {
			redoActions ~= backup(undoActions[$ - 1].min, undoActions[$ - 1].max);
			restore(undoActions[$ - 1]);
			undoActions.length--;
		}
	}

	void redo()
	{
		if (redoActions.length > 0) {
			undoActions ~= backup(redoActions[$ - 1].min, redoActions[$ - 1].max);
			restore(redoActions[$ - 1]);
			redoActions.length--;
		}
	}

	private void restore(const ref Action action)
	{
		write(action.min, action.max, action.blocks);
	}

	private Action backup(const ref uint[3] min, const ref uint[3] max)
	{
		Action action;
		action.min = min;
		action.max = max;
		read(min, max, action.blocks);
		return action;
	}

	private void read(const ref uint[3] min, const ref uint[3] max, ref WorldBlock[] blocks)
	{
		int n = 0;
		blocks.length = (max[0] - min[0]) * (max[1] - min[1]) * (max[2] - min[2]);
		for (uint x = min[0]; x < max[0]; x++) {
			for (uint y = min[1]; y < max[1]; y++) {
				for (uint z = min[2]; z < max[2]; z++) {
					blocks[n++] = root.getBlock(x, y, z);
				}
			}
		}
	}

	private void write(const ref uint[3] min, const ref uint[3] max, const WorldBlock[] blocks)
	{
		int n = 0;
		for (uint x = min[0]; x < max[0]; x++) {
			for (uint y = min[1]; y < max[1]; y++) {
				for (uint z = min[2]; z < max[2]; z++) {
					root.insertBlock(blocks[n++], x, y, z);
				}
			}
		}
	}
}
