/* -*- c-file-style: "ruby"; indent-tabs-mode: nil -*- */
/************************************************

  rbatkversion.h -

  This file was generated by mkmf-gnome2.rb.

************************************************/

#ifndef __RBATK_VERSION_H__
#define __RBATK_VERSION_H__

#define ATK_MAJOR_VERSION (1)
#define ATK_MINOR_VERSION (12)
#define ATK_MICRO_VERSION (3)

#define ATK_CHECK_VERSION(major,minor,micro)    \
    (ATK_MAJOR_VERSION > (major) || \
     (ATK_MAJOR_VERSION == (major) && ATK_MINOR_VERSION > (minor)) || \
     (ATK_MAJOR_VERSION == (major) && ATK_MINOR_VERSION == (minor) && \
      ATK_MICRO_VERSION >= (micro)))


#endif /* __RBATK_VERSION_H__ */
