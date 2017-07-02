module freetype;
import core.stdc.config: c_long, c_ulong;

extern (C) nothrow:

enum {
	FT_LCD_FILTER_NONE    = 0,
	FT_LCD_FILTER_DEFAULT = 1,
	FT_LCD_FILTER_LIGHT   = 2,
	FT_LCD_FILTER_LEGACY  = 16,
	FT_LCD_FILTER_MAX
}
alias const int FT_LcdFilter;

private FT_Int32 FT_LOAD_TARGET_(FT_Int32 x) {
	return (x & 15) << 16;
}

enum {
	FT_LOAD_TARGET_NORMAL  = FT_LOAD_TARGET_(FT_RENDER_MODE_NORMAL),
	FT_LOAD_TARGET_LIGHT   = FT_LOAD_TARGET_(FT_RENDER_MODE_LIGHT),
	FT_LOAD_TARGET_MONO    = FT_LOAD_TARGET_(FT_RENDER_MODE_MONO),
	FT_LOAD_TARGET_LCD     = FT_LOAD_TARGET_(FT_RENDER_MODE_LCD),
	FT_LOAD_TARGET_LCD_V   = FT_LOAD_TARGET_(FT_RENDER_MODE_LCD_V)
}

enum {
	FT_RENDER_MODE_NORMAL = 0,
	FT_RENDER_MODE_LIGHT,
	FT_RENDER_MODE_MONO,
	FT_RENDER_MODE_LCD,
	FT_RENDER_MODE_LCD_V,
	FT_RENDER_MODE_MAX
}
alias const int FT_Render_Mode;

enum {
	FT_SIZE_REQUEST_TYPE_NOMINAL,
	FT_SIZE_REQUEST_TYPE_REAL_DIM,
	FT_SIZE_REQUEST_TYPE_BBOX,
	FT_SIZE_REQUEST_TYPE_CELL,
	FT_SIZE_REQUEST_TYPE_SCALES,
	FT_SIZE_REQUEST_TYPE_MAX
}
alias const int FT_Size_Request_Type;

enum {
	FT_LOAD_DEFAULT                      = 0x0,
	FT_LOAD_NO_SCALE                     = ( 1L << 0 ),
	FT_LOAD_NO_HINTING                   = ( 1L << 1 ),
	FT_LOAD_RENDER                       = ( 1L << 2 ),
	FT_LOAD_NO_BITMAP                    = ( 1L << 3 ),
	FT_LOAD_VERTICAL_LAYOUT              = ( 1L << 4 ),
	FT_LOAD_FORCE_AUTOHINT               = ( 1L << 5 ),
	FT_LOAD_CROP_BITMAP                  = ( 1L << 6 ),
	FT_LOAD_PEDANTIC                     = ( 1L << 7 ),
	FT_LOAD_IGNORE_GLOBAL_ADVANCE_WIDTH  = ( 1L << 9 ),
	FT_LOAD_NO_RECURSE                   = ( 1L << 10 ),
	FT_LOAD_IGNORE_TRANSFORM             = ( 1L << 11 ),
	FT_LOAD_MONOCHROME                   = ( 1L << 12 ),
	FT_LOAD_LINEAR_DESIGN                = ( 1L << 13 ),
	FT_LOAD_NO_AUTOHINT                  = ( 1L << 15 )
}

enum {
	FT_FACE_FLAG_SCALABLE          = ( 1L <<  0 ),
	FT_FACE_FLAG_FIXED_SIZES       = ( 1L <<  1 ),
	FT_FACE_FLAG_FIXED_WIDTH       = ( 1L <<  2 ),
	FT_FACE_FLAG_SFNT              = ( 1L <<  3 ),
	FT_FACE_FLAG_HORIZONTAL        = ( 1L <<  4 ),
	FT_FACE_FLAG_VERTICAL          = ( 1L <<  5 ),
	FT_FACE_FLAG_KERNING           = ( 1L <<  6 ),
	FT_FACE_FLAG_FAST_GLYPHS       = ( 1L <<  7 ),
	FT_FACE_FLAG_MULTIPLE_MASTERS  = ( 1L <<  8 ),
	FT_FACE_FLAG_GLYPH_NAMES       = ( 1L <<  9 ),
	FT_FACE_FLAG_EXTERNAL_STREAM   = ( 1L << 10 ),
	FT_FACE_FLAG_HINTER            = ( 1L << 11 ),
	FT_FACE_FLAG_CID_KEYED         = ( 1L << 12 ),
	FT_FACE_FLAG_TRICKY            = ( 1L << 13 )
}

enum {
	FT_KERNING_DEFAULT = 0,
	FT_KERNING_UNFITTED,
	FT_KERNING_UNSCALED
}
//alias const int FT_Kerning_Mode_;
//alias const int FT_Kerning_Mode;

/* Types */
alias c_long FT_Pos;
alias ubyte FT_Bool;
alias short FT_FWord; 
alias ushort FT_UFWord; 
alias char FT_Char;
alias ubyte FT_Byte;
alias char FT_String;
alias short FT_Short;
alias ushort FT_UShort;
alias int FT_Int;
alias uint FT_UInt;
alias int FT_Int32;
alias uint FT_UInt32;
alias c_long FT_Long;
alias c_ulong FT_ULong;
alias short FT_F2Dot14;
alias c_long FT_F26Dot6;
alias c_long FT_Fixed;
alias int FT_Error;
alias void* FT_Pointer;
alias FT_Pointer FT_Module_Interface;
alias c_ulong FT_Glyph_Format;
alias c_ulong FT_Encoding;

/* Constants */
const int FT_MAX_MODULES = 32;

/* Function Pointers */
alias void* function(FT_Memory, c_long) FT_Alloc_Func;
alias void function(FT_Memory, void*) FT_Free_Func;
alias void* function(FT_Memory, c_long, c_long, void*) FT_Realloc_Func;
alias void function(void*) FT_Generic_Finalizer;
alias FT_Error function(FT_Module) FT_Module_Constructor;
alias void function(FT_Module) FT_Module_Destructor;
alias FT_Module_Interface function(FT_Module, char*) FT_Module_Requester;
alias void function(void*) FT_DebugHook_Func;
alias FT_Error function(FT_Renderer, FT_GlyphSlot, FT_UInt, FT_Vector*) FT_Renderer_RenderFunc;
alias FT_Error function(FT_Renderer, FT_GlyphSlot, FT_Matrix*, FT_Vector*) FT_Renderer_TransformFunc;
alias void function(FT_Renderer, FT_GlyphSlot, FT_BBox*) FT_Renderer_GetCBoxFunc;
alias FT_Error function(FT_Renderer, FT_ULong, FT_Pointer) FT_Renderer_SetModeFunc;
alias FT_Error function(FT_Stream, FT_Face, FT_Int, FT_Int, FT_Parameter*) FT_Face_InitFunc;
alias FT_ULong function(FT_Stream, FT_Byte*, FT_ULong) FT_Stream_ReadFunc;
alias FT_Error function(FT_Stream, FT_ULong) FT_Stream_SeekFunc;
alias c_ulong function(FT_Stream, c_ulong, ubyte*, c_ulong) FT_Stream_IoFunc;
alias void function(FT_Stream) FT_Stream_CloseFunc;
alias void function(FT_Face) FT_Face_DoneFunc;
alias FT_Error function(FT_Size) FT_Size_InitFunc;
alias void function(FT_Size) FT_Size_DoneFunc;
alias FT_Error function(FT_GlyphSlot) FT_Slot_InitFunc;
alias void function(FT_GlyphSlot) FT_Slot_DoneFunc;
alias FT_Error function(FT_Size, FT_F26Dot6, FT_F26Dot6, FT_UInt, FT_UInt) FT_Size_ResetPointsFunc;
alias FT_Error function(FT_Size, FT_UInt, FT_UInt) FT_Size_ResetPixelsFunc;
alias FT_Error function( FT_GlyphSlot, FT_Size, FT_UInt, FT_Int) FT_Slot_LoadFunc;
alias FT_Error function(FT_Face, FT_UInt, FT_UInt, FT_Vector*) FT_Face_GetKerningFunc;
alias FT_Error function(FT_Face, FT_Stream) FT_Face_AttachFunc;
alias FT_Error function(FT_Face, FT_UInt, FT_UInt, FT_Bool, FT_UShort*) FT_Face_GetAdvancesFunc;
//alias FT_Error (*FT_Incremental_GetGlyphDataFunc)(FT_Incremental, FT_UInt, FT_Data*);
//alias void (*FT_Incremental_FreeGlyphDataFunc)(FT_Incremental, FT_Data*);
//alias FT_Error (*FT_Incremental_GetGlyphMetricsFunc)(FT_Incremental, FT_UInt, FT_Bool, FT_Incremental_MetricsRec*);
//alias int (*FT_Raster_NewFunc)(void*, FT_Raster*);
//alias void (*FT_Raster_DoneFunc)(FT_Raster);
//alias void (*FT_Raster_ResetFunc)(FT_Raster, ubyte*, ulong);
//alias int (*FT_Raster_SetModeFunc)(FT_Raster, ulong, void*);
//alias int(*FT_Raster_RenderFunc)(FT_Raster, FT_Raster_Params*);
alias FT_Error function(FT_Glyph, FT_GlyphSlot) FT_Glyph_InitFunc;
alias void function(FT_Glyph) FT_Glyph_DoneFunc;
alias void function(FT_Glyph, FT_Matrix*, FT_Vector*) FT_Glyph_TransformFunc;
alias void function(FT_Glyph, FT_BBox*) FT_Glyph_GetBBoxFunc;
alias FT_Error function(FT_Glyph, FT_Glyph) FT_Glyph_CopyFunc;
alias FT_Error function(FT_Glyph, FT_GlyphSlot) FT_Glyph_PrepareFunc;

//alias FT_Raster_RenderFunc FT_Raster_RenderFunc;

FT_Error FT_Init_FreeType(FT_Library*);
FT_UInt FT_Get_Char_Index(const FT_Face, FT_ULong);
void FT_Done_GlyphSlot(FT_GlyphSlot);
void FT_Done_Memory(FT_Memory);
FT_Error FT_Done_FreeType(FT_Library);
FT_Error FT_Done_Face(FT_Face);
FT_Error FT_Get_Kerning(const FT_Face, FT_UInt, FT_UInt, FT_UInt, FT_Vector*);
FT_Error FT_Library_SetLcdFilter(FT_Library library, FT_LcdFilter filter);
FT_Error FT_Library_SetLcdFilterWeights(FT_Library library, const(char) *weights);
FT_Error FT_Load_Char(FT_Face, FT_ULong, FT_Int32);
FT_Error FT_Load_Glyph(FT_Face, FT_Int, FT_Int32);
FT_Error FT_Load_Glyph(FT_Face, FT_Int);
FT_Error FT_New_Face(FT_Library, FT_Face);
FT_Error FT_New_Face(FT_Library, const(char)* filepathname, FT_Long, FT_Face*);
FT_Error FT_Request_Size( FT_Face face, FT_Size_Request  req );
FT_Error FT_Set_Char_Size(FT_Face, FT_F26Dot6, FT_F26Dot6, FT_UInt, FT_UInt);
FT_Error FT_Set_Pixel_Sizes(FT_Face, FT_UInt, FT_UInt);

struct FT_Incremental_InterfaceRec
{
	const FT_Incremental_FuncsRec* funcs;
	//FT_Incremental object;
}
alias FT_Incremental_InterfaceRec* FT_Incremental_Interface;

struct FT_Face_InternalRec
{
    FT_UShort max_points;
    FT_Short max_contours;
    FT_Matrix transform_matrix;
    FT_Vector transform_delta;
    FT_Int transform_flags;
    FT_ServiceCacheRec services;
    FT_Incremental_InterfaceRec* incremental_interface;
}
alias FT_Face_InternalRec* FT_Face_Internal;

struct FT_ServiceCacheRec
{
	FT_Pointer service_POSTSCRIPT_FONT_NAME;
	FT_Pointer service_MULTI_MASTERS;
	FT_Pointer service_GLYPH_DICT;
	FT_Pointer service_PFR_METRICS;
	FT_Pointer service_WINFNT;
}
alias FT_ServiceCacheRec* FT_ServiceCache;

struct FT_Size_RequestRec
{
	FT_Size_Request_Type type;
	FT_Long width;
	FT_Long height;
	FT_UInt horiResolution;
	FT_UInt vertResolution;
}
alias FT_Size_RequestRec* FT_Size_Request;

// Incrimental Functions
struct FT_Incremental_FuncsRec_
{
	//FT_Incremental_GetGlyphDataFunc get_glyph_data;
	//FT_Incremental_FreeGlyphDataFunc free_glyph_data;
	//FT_Incremental_GetGlyphMetricsFunc get_glyph_metrics;
};
alias FT_Incremental_FuncsRec_ FT_Incremental_FuncsRec;
alias FT_Incremental_FuncsRec_* FT_Incremental_Funcs;

// Incrimental Metrics
struct FT_Incremental_MetricsRec_
{
	FT_Long bearing_x;
	FT_Long bearing_y;
	FT_Long advance;
};
alias FT_Incremental_MetricsRec_ FT_Incremental_MetricsRec;
alias FT_Incremental_MetricsRec_* FT_Incremental_Metrics;

// Steam Class
struct FT_Stream_ClassRec_
{
	//FT_ClassRec clazz;
	FT_Stream_ReadFunc stream_read;
	FT_Stream_SeekFunc stream_seek;
};
alias FT_Stream_ClassRec_ FT_Stream_ClassRec;
alias FT_Stream_ClassRec_* FT_Stream_Class;

// Stream Description
union FT_StreamDesc_
{
	c_long value;
	void* pointer;
};
alias FT_StreamDesc_ FT_StreamDesc;

// Stream
struct FT_StreamRec_
{
	ubyte* base;
	c_ulong size;
	c_ulong pos;
	FT_StreamDesc descriptor;
	FT_StreamDesc pathname;
	FT_Stream_IoFunc read;
	FT_Stream_CloseFunc close;
	FT_Memory memory;
	ubyte* cursor;
	ubyte* limit;
};
alias FT_StreamRec_ FT_StreamRec;
alias FT_StreamRec_* FT_Stream;

// Parameter
struct FT_Parameter_
{
	FT_ULong tag;
	FT_Pointer data;
};
alias FT_Parameter_ FT_Parameter;

// Glyph Metrics
struct FT_Glyph_Metrics_
{
	FT_Pos width;
	FT_Pos height;
	FT_Pos horiBearingX;
	FT_Pos horiBearingY;
	FT_Pos horiAdvance;
	FT_Pos vertBearingX;
	FT_Pos vertBearingY;
	FT_Pos vertAdvance;
};
alias FT_Glyph_Metrics_ FT_Glyph_Metrics;

// Bitmap
struct FT_Bitmap_
{
	int rows;
	int width;
	int pitch;
	ubyte* buffer;
	short num_grays;
	char pixel_mode;
	char palette_mode;
	void* palette;
};
alias FT_Bitmap_ FT_Bitmap;

// Outline
struct FT_Outline_
{
	short n_contours; 
	short n_points; 
	FT_Vector* points; 
	char* tags; 
	short* contours; 
	int flags; 
};
alias FT_Outline_ FT_Outline;

// Sub Glyph
struct FT_SubGlyphRec_
{
	FT_Int index;
	FT_UShort flags;
	FT_Int arg1;
	FT_Int arg2;
	FT_Matrix transform;
};
alias FT_SubGlyphRec_ FT_SubGlyphRec;
alias FT_SubGlyphRec_* FT_SubGlyph;

// Internal Slot
struct FT_Slot_InternalRec_
{
	FT_GlyphLoader loader;
	FT_UInt flags;
	FT_Bool glyph_transformed;
	FT_Matrix glyph_matrix;
	FT_Vector glyph_delta;
	void* glyph_hints;
};
alias FT_Slot_InternalRec_ FT_Slot_InternalRec;
alias FT_Slot_InternalRec_* FT_Slot_Internal;

// Glyph Load
struct FT_GlyphLoadRec_
{
	FT_Outline outline;
	FT_Vector* extra_points;
	FT_UInt num_subglyphs;
	FT_SubGlyph subglyphs;
};
alias FT_GlyphLoadRec_ FT_GlyphLoadRec;
alias FT_GlyphLoadRec_* FT_GlyphLoad;

// Size
struct FT_SizeRec_
{
	FT_Face face;
	FT_Generic generic;
	FT_Size_Metrics metrics;
	//FT_Size_Internal internal;
};
alias FT_SizeRec_ FT_SizeRec;
alias FT_SizeRec_* FT_Size;

// Driver Class
struct FT_Driver_ClassRec_
{
	FT_Module_Class root;
	FT_Long face_object_size;
	FT_Long size_object_size;
	FT_Long slot_object_size;
	FT_Face_InitFunc init_face;
	FT_Face_DoneFunc done_face;
	FT_Size_InitFunc init_size;
	FT_Size_DoneFunc done_size;
	FT_Slot_InitFunc init_slot;
	FT_Slot_DoneFunc done_slot;
	FT_Size_ResetPointsFunc set_char_sizes;
	FT_Size_ResetPixelsFunc set_pixel_sizes;
	FT_Slot_LoadFunc load_glyph;
	FT_Face_GetKerningFunc get_kerning;
	FT_Face_AttachFunc attach_file;
	FT_Face_GetAdvancesFunc get_advances;
};
alias FT_Driver_ClassRec_ FT_Driver_ClassRec;
alias FT_Driver_ClassRec_* FT_Driver_Class;

// Driver
struct FT_DriverRec_
{
	FT_ModuleRec root;
	FT_Driver_Class clazz;
	FT_ListRec faces_list;
	void* extensions;
	FT_GlyphLoader glyph_loader;
};
alias FT_DriverRec_ FT_DriverRec;
alias FT_DriverRec_* FT_Driver;

// Size Metrics
struct FT_Size_Metrics_
{
	FT_UShort x_ppem;
	FT_UShort y_ppem;
	FT_Fixed x_scale;
	FT_Fixed y_scale;
	FT_Pos ascender;
	FT_Pos descender;
	FT_Pos height;
	FT_Pos max_advance;
};
alias FT_Size_Metrics_ FT_Size_Metrics;


// Glyph Loader
struct FT_GlyphLoaderRec_
{
	FT_Memory        memory;
	FT_UInt          max_points;
	FT_UInt          max_contours;
	FT_UInt          max_subglyphs;
	FT_Bool          use_extra;
	FT_GlyphLoadRec  base;
	FT_GlyphLoadRec  current;
	void*            other;
};
alias FT_GlyphLoaderRec_ FT_GlyphLoaderRec;
alias FT_GlyphLoaderRec_* FT_GlyphLoader;

// List Node
struct FT_ListNodeRec_
{
	FT_ListNode prev;
	FT_ListNode next;
	void* data;
};
alias FT_ListNodeRec_ FT_ListNodeRec;
alias FT_ListNodeRec_* FT_ListNode;

// List
struct FT_ListRec_
{
	FT_ListNode head;
	FT_ListNode tail;
};
alias FT_ListRec_ FT_ListRec;
alias FT_ListRec_* FT_List;

// Renderer Class
struct FT_Renderer_Class_
{
	FT_Module_Class root;
	FT_Glyph_Format glyph_format;
	FT_Renderer_RenderFunc render_glyph;
	FT_Renderer_TransformFunc transform_glyph;
	FT_Renderer_GetCBoxFunc get_glyph_cbox;
	FT_Renderer_SetModeFunc set_mode;
	FT_Raster_Funcs* raster_class;
};
alias FT_Renderer_Class_ FT_Renderer_Class;

// Renderer
struct FT_RendererRec_
{
	FT_ModuleRec root;
	FT_Renderer_Class* clazz;
	FT_Glyph_Format glyph_format;
	FT_Glyph_Class glyph_class;
	//FT_Raster raster;
	//FT_Raster_Render_Func raster_render;
	FT_Renderer_RenderFunc render;
};
alias FT_RendererRec_ FT_RendererRec;
alias FT_RendererRec_* FT_Renderer;

// Memory
struct FT_MemoryRec_
{
	void* user;
	FT_Alloc_Func alloc;
	FT_Free_Func free;
	FT_Realloc_Func realloc;
};
alias FT_MemoryRec_ FT_MemoryRec;
alias FT_MemoryRec_* FT_Memory;

// Library
struct FT_LibraryRec_
{
	FT_Memory memory;
	FT_Generic generic;
	FT_Int version_major;
	FT_Int version_minor;
	FT_Int version_patch;
	FT_UInt num_modules;
	FT_Module[FT_MAX_MODULES] modules;
	FT_ListRec renderers;
	FT_Renderer cur_renderer;
	FT_Module auto_hinter;
	FT_Byte* raster_pool;
	FT_ULong raster_pool_size;
	FT_DebugHook_Func[4] debug_hooks;
};
alias FT_LibraryRec_ FT_LibraryRec;
alias FT_LibraryRec_* FT_Library;

// Module
struct FT_ModuleRec_
{
	FT_Module_Class* clazz;
	FT_Library library;
	FT_Memory memory;
	FT_Generic generic;
};
alias FT_ModuleRec_ FT_ModuleRec;
alias FT_ModuleRec_* FT_Module;

// Module Class
struct FT_Module_Class_
{
	FT_ULong module_flags;
	FT_Long module_size;
	const FT_String* module_name;
	FT_Fixed module_version;
	FT_Fixed module_requires;
	const void* module_interface;
	FT_Module_Constructor module_init;
	FT_Module_Destructor module_done;
	FT_Module_Requester get_interface;
};
alias FT_Module_Class_ FT_Module_Class;

// Generic
struct FT_Generic_
{
	void* data;
	FT_Generic_Finalizer finalizer;
};
alias FT_Generic_ FT_Generic;

// Face
struct FT_FaceRec_
{
	FT_Long num_faces;
	FT_Long face_index;
	FT_Long face_flags;
	FT_Long style_flags;
	FT_Long num_glyphs;
	FT_String* family_name;
	FT_String* style_name;
	FT_Int num_fixed_sizes;
	FT_Bitmap_Size* available_sizes;
	FT_Int num_charmaps;
	FT_CharMap* charmaps;
	FT_Generic generic;
	FT_BBox bbox;
	FT_UShort units_per_EM;
	FT_Short ascender;
	FT_Short descender;
	FT_Short height;
	FT_Short max_advance_width;
	FT_Short max_advance_height;
	FT_Short underline_position;
	FT_Short underline_thickness;
	FT_GlyphSlot glyph;
	FT_Size size;
	FT_CharMap charmap;
	FT_Driver driver;
	FT_Memory memory;
	FT_Stream stream;
	FT_ListRec sizes_list;
	FT_Generic autohint;
	void* extensions;
	FT_Face_Internal internal;
};
alias FT_FaceRec_ FT_FaceRec;
alias FT_FaceRec_* FT_Face;


// Glyph
struct FT_GlyphRec_
{
	FT_Library library;
	const FT_Glyph_Class* clazz;
	FT_Glyph_Format format;
	FT_Vector advance;
};
alias FT_GlyphRec_ FT_GlyphRec;
alias FT_GlyphRec_* FT_Glyph;

// Glyph Slot
struct FT_GlyphSlotRec_
{
	FT_Library library;
	FT_Face face;
	FT_GlyphSlot next;
	FT_UInt reserved;
	FT_Generic generic;
	FT_Glyph_Metrics metrics;
	FT_Fixed linearHoriAdvance;
	FT_Fixed linearVertAdvance;
	FT_Vector advance;
	FT_Glyph_Format format;
	FT_Bitmap bitmap;
	FT_Int bitmap_left;
	FT_Int bitmap_top;
	FT_Outline outline;
	FT_UInt num_subglyphs;
	FT_SubGlyph subglyphs;
	void* control_data;
	c_long control_len;
	void* other;
	FT_Slot_Internal internal;
};
alias FT_GlyphSlotRec_ FT_GlyphSlotRec;
alias FT_GlyphSlotRec_* FT_GlyphSlot;

// Vector
struct FT_Vector_
{
	FT_Pos x;
	FT_Pos y;
};
alias FT_Vector_ FT_Vector;

// Matrix
struct FT_Matrix_
{
	FT_Fixed xx, xy;
	FT_Fixed yx, yy;
};
alias FT_Matrix_ FT_Matrix;

// Bounding Box
struct FT_BBox_
{
	FT_Pos xMin, yMin;
	FT_Pos xMax, yMax;
};
alias FT_BBox_ FT_BBox;

// Raster Functions
struct FT_Raster_Funcs_
{
	FT_Glyph_Format glyph_format;
	//FT_Raster_NewFunc raster_new;
	//FT_Raster_ResetFunc raster_reset;
	//FT_Raster_SetModeFunc raster_set_mode;
	//FT_Raster_RenderFunc raster_render;
	//FT_Raster_DoneFunc raster_done;
};
alias FT_Raster_Funcs_ FT_Raster_Funcs;

// Glyph Class
struct FT_Glyph_Class_
{
	FT_Long glyph_size;
	FT_Glyph_Format glyph_format;
	FT_Glyph_InitFunc glyph_init;
	FT_Glyph_DoneFunc glyph_done;
	FT_Glyph_CopyFunc glyph_copy;
	FT_Glyph_TransformFunc glyph_transform;
	FT_Glyph_GetBBoxFunc glyph_bbox;
	FT_Glyph_PrepareFunc glyph_prepare;
};
alias FT_Glyph_Class_ FT_Glyph_Class;

// Bitmap Size
struct FT_Bitmap_Size_
{
	FT_Short height;
	FT_Short width;
	FT_Pos size;
	FT_Pos x_ppem;
	FT_Pos y_ppem;
};
alias FT_Bitmap_Size_ FT_Bitmap_Size;

// Character Map
struct FT_CharMapRec_
{
	FT_Face face;
	FT_Encoding encoding;
	FT_UShort platform_id;
	FT_UShort encoding_id;
};
alias FT_CharMapRec_ FT_CharMapRec;
alias FT_CharMapRec_* FT_CharMap;


//Macros
bool FT_HAS_KERNING()(FT_Face face)
{
	return (face.face_flags & FT_FACE_FLAG_KERNING) != 0;
}