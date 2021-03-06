/* -*- c-file-style: "ruby"; indent-tabs-mode: nil -*- */
/************************************************

  rbpango.h -

  $Author: ktou $
  $Date: 2005/10/05 11:16:26 $

  Copyright (C) 2002-2005 Masao Mutoh
************************************************/

#include "ruby.h"
#define PANGO_ENABLE_ENGINE
#define PANGO_ENABLE_BACKEND
#include <pango/pango.h>

#if HAVE_FREETYPE2
#include <pango/pangofc-font.h>
#endif

#include "rbgobject.h"
#include "rbpangoversion.h"

#if PANGO_CHECK_VERSION(1,10,0)
#include <pango/pangocairo.h>
#  if HAVE_RB_CAIRO_H
#include <rb_cairo.h>
#  endif
#endif

#if defined(G_PLATFORM_WIN32) && !defined(RUBY_PANGO_STATIC_COMPILATION)
#  ifdef RUBY_PANGO_COMPILATION
#    define RUBY_PANGO_VAR __declspec(dllexport)
#  else
#    define RUBY_PANGO_VAR extern __declspec(dllimport)
#  endif
#else
#  define RUBY_PANGO_VAR extern
#endif

extern void Init_pango_inits();
RUBY_PANGO_VAR VALUE mPango;

#ifndef PANGO_TYPE_ITEM
#define PANGO_TYPE_ITEM (pango_item_get_type())
#endif
#define PANGO_TYPE_ANALYSIS (pango_analysis_get_type())
#define PANGO_TYPE_LOG_ATTR (pango_log_attr_get_type())
#ifndef PANGO_TYPE_LAYOUT_ITER
#define PANGO_TYPE_LAYOUT_ITER (pango_layout_iter_get_type())
#endif
#ifndef PANGO_TYPE_LAYOUT_LINE
#define PANGO_TYPE_LAYOUT_LINE (pango_layout_line_get_type())
#endif
#define PANGO_TYPE_RECTANGLE (pango_rectangle_get_type())
#define PANGO_TYPE_ATTR_ITERATOR (pango_attr_iter_get_type())
#define PANGO_TYPE_COVERAGE (pango_coverage_get_type())
#define PANGO_TYPE_GLYPH_INFO (pango_glyph_info_get_type())
#define PANGO_TYPE_GLYPH_ITEM (pango_glyph_item_get_type())

#if PANGO_CHECK_VERSION(1,4,0)
#define PANGO_TYPE_SCRIPT_ITER (pango_script_iter_get_type())
#endif

#define ATTR2RVAL(attr) (pango_make_attribute(attr))
#define RVAL2ATTR(attr) (pango_get_attribute(attr))
#define ATTRTYPE2CLASS(attr_type) (pango_get_attribute_klass(attr_type))
#define RBPANGO_ADD_ATTRIBUTE(type, klass) (pango_add_attribute(type, klass))

extern VALUE pango_make_attribute(PangoAttribute* attr);
extern PangoAttribute* pango_get_attribute(VALUE attr);

extern GType pango_item_get_type();
extern GType pango_analysis_get_type();
extern GType pango_log_attr_get_type();
extern GType pango_layout_iter_get_type();
extern GType pango_layout_line_get_type();
extern GType pango_rectangle_get_type();
extern GType pango_attr_iter_get_type();
extern GType pango_coverage_get_type();
extern GType pango_glyph_info_get_type();
extern GType pango_glyph_item_get_type();

#if PANGO_CHECK_VERSION(1,4,0)
extern GType pango_script_iter_get_type();
#endif

extern VALUE pango_get_attribute_klass(VALUE attr_type);
extern void pango_add_attribute(int attr_type, VALUE klass);
