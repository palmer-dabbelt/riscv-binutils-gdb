# This shell script emits a C file. -*- C -*-
# It does some substitutions.
cat >e${EMULATION_NAME}.c <<EOF
/* This file is part of GLD, the Gnu Linker.
   Copyright 1995, 96, 97, 1998 Free Software Foundation, Inc.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.  */

/* For WINDOWS_NT */
/* The original file generated returned different default scripts depending
   on whether certain switches were set, but these switches pertain to the
   Linux system and that particular version of coff.  In the NT case, we
   only determine if the subsystem is console or windows in order to select
   the correct entry point by default. */ 
  
#include "bfd.h"
#include "sysdep.h"
#include "bfdlink.h"
#include "getopt.h"
#include "libiberty.h"
#include "ld.h"
#include "ldmain.h"
#include "ldgram.h"
#include "ldexp.h"
#include "ldlang.h"
#include "ldemul.h"
#include "ldlex.h"
#include "ldmisc.h"
#include "ldctor.h"
#include "ldfile.h"
#include "coff/internal.h"
#include "../bfd/libcoff.h"

#define TARGET_IS_${EMULATION_NAME}

static void gld_${EMULATION_NAME}_set_symbols PARAMS ((void));
static void gld_${EMULATION_NAME}_after_open PARAMS ((void));
static void gld_${EMULATION_NAME}_before_parse PARAMS ((void));
static void gld_${EMULATION_NAME}_after_parse PARAMS ((void));
static void gld_${EMULATION_NAME}_before_allocation PARAMS ((void));
static boolean gld_${EMULATION_NAME}_place_orphan
  PARAMS ((lang_input_statement_type *, asection *));
static void gld${EMULATION_NAME}_place_section
  PARAMS ((lang_statement_union_type *));
static char *gld_${EMULATION_NAME}_get_script PARAMS ((int *));
static int gld_${EMULATION_NAME}_parse_args PARAMS ((int, char **));

static struct internal_extra_pe_aouthdr pe;
static int dll;
static int support_old_code = 0;

extern const char *output_filename;

static void
gld_${EMULATION_NAME}_before_parse()
{
  output_filename = "a.exe";
  ldfile_output_architecture = bfd_arch_${ARCH};
}

/* PE format extra command line options.  */

/* Used for setting flags in the PE header. */
#define OPTION_BASE_FILE		(300  + 1)
#define OPTION_DLL			(OPTION_BASE_FILE + 1)
#define OPTION_FILE_ALIGNMENT		(OPTION_DLL + 1)
#define OPTION_IMAGE_BASE		(OPTION_FILE_ALIGNMENT + 1)
#define OPTION_MAJOR_IMAGE_VERSION	(OPTION_IMAGE_BASE + 1)
#define OPTION_MAJOR_OS_VERSION		(OPTION_MAJOR_IMAGE_VERSION + 1)
#define OPTION_MAJOR_SUBSYSTEM_VERSION	(OPTION_MAJOR_OS_VERSION + 1)
#define OPTION_MINOR_IMAGE_VERSION	(OPTION_MAJOR_SUBSYSTEM_VERSION + 1)
#define OPTION_MINOR_OS_VERSION		(OPTION_MINOR_IMAGE_VERSION + 1)
#define OPTION_MINOR_SUBSYSTEM_VERSION	(OPTION_MINOR_OS_VERSION + 1)
#define OPTION_SECTION_ALIGNMENT	(OPTION_MINOR_SUBSYSTEM_VERSION + 1)
#define OPTION_STACK                    (OPTION_SECTION_ALIGNMENT + 1)
#define OPTION_SUBSYSTEM                (OPTION_STACK + 1)
#define OPTION_HEAP			(OPTION_SUBSYSTEM + 1)
#define OPTION_SUPPORT_OLD_CODE		(OPTION_HEAP + 1)

static struct option longopts[] =
{
  /* PE options */
  {"base-file", required_argument, NULL, OPTION_BASE_FILE},
  {"dll", no_argument, NULL, OPTION_DLL},
  {"file-alignment", required_argument, NULL, OPTION_FILE_ALIGNMENT},
  {"heap", required_argument, NULL, OPTION_HEAP}, 
  {"image-base", required_argument, NULL, OPTION_IMAGE_BASE},
  {"major-image-version", required_argument, NULL, OPTION_MAJOR_IMAGE_VERSION},
  {"major-os-version", required_argument, NULL, OPTION_MAJOR_OS_VERSION},
  {"major-subsystem-version", required_argument, NULL, OPTION_MAJOR_SUBSYSTEM_VERSION},
  {"minor-image-version", required_argument, NULL, OPTION_MINOR_IMAGE_VERSION},
  {"minor-os-version", required_argument, NULL, OPTION_MINOR_OS_VERSION},
  {"minor-subsystem-version", required_argument, NULL, OPTION_MINOR_SUBSYSTEM_VERSION},
  {"section-alignment", required_argument, NULL, OPTION_SECTION_ALIGNMENT},
  {"stack", required_argument, NULL, OPTION_STACK},
  {"subsystem", required_argument, NULL, OPTION_SUBSYSTEM},
  {"support-old-code", no_argument, NULL, OPTION_SUPPORT_OLD_CODE},
  {NULL, no_argument, NULL, 0}
};


/* PE/WIN32; added routines to get the subsystem type, heap and/or stack
   parameters which may be input from the command line */

typedef struct
{
  void *ptr;
  int size;
  int value;
  char *symbol;
  int inited;
} definfo;

#define D(field,symbol,def)  {&pe.field,sizeof(pe.field), def, symbol,0}

static definfo init[] =
{
  /* imagebase must be first */
#define IMAGEBASEOFF 0
  D(ImageBase,"__image_base__", NT_EXE_IMAGE_BASE),
#define DLLOFF 1
  {&dll, sizeof(dll), 0, "__dll__"},
  D(SectionAlignment,"__section_alignment__", PE_DEF_SECTION_ALIGNMENT),
  D(FileAlignment,"__file_alignment__", PE_DEF_FILE_ALIGNMENT),
  D(MajorOperatingSystemVersion,"__major_os_version__", 4),
  D(MinorOperatingSystemVersion,"__minor_os_version__", 0),
  D(MajorImageVersion,"__major_image_version__", 1),
  D(MinorImageVersion,"__minor_image_version__", 0),
  D(MajorSubsystemVersion,"__major_subsystem_version__", 4),
  D(MinorSubsystemVersion,"__minor_subsystem_version__", 0),
  D(Subsystem,"__subsystem__", 3),
  D(SizeOfStackReserve,"__size_of_stack_reserve__", 0x2000000),
  D(SizeOfStackCommit,"__size_of_stack_commit__", 0x1000),
  D(SizeOfHeapReserve,"__size_of_heap_reserve__", 0x100000),
  D(SizeOfHeapCommit,"__size_of_heap_commit__", 0x1000),
  D(LoaderFlags,"__loader_flags__", 0x0),
  { NULL, 0, 0, NULL, 0 }
};

static void
gld_${EMULATION_NAME}_list_options (file)
     FILE * file;
{
  fprintf (file, _("  --base_file <basefile>             Generate a base file for relocatable DLLs\n"));
  fprintf (file, _("  --dll                              Set image base to the default for DLLs\n"));
  fprintf (file, _("  --file-alignment <size>            Set file alignment\n"));
  fprintf (file, _("  --heap <size>                      Set initial size of the heap\n"));
  fprintf (file, _("  --image-base <address>             Set start address of the executable\n"));
  fprintf (file, _("  --major-image-version <number>     Set version number of the executable\n"));
  fprintf (file, _("  --major-os-version <number>        Set minimum required OS version\n"));
  fprintf (file, _("  --major-subsystem-version <number> Set minimum required OS subsystem version\n"));
  fprintf (file, _("  --minor-image-version <number>     Set revision number of the executable\n"));
  fprintf (file, _("  --minor-os-version <number>        Set minimum required OS revision\n"));
  fprintf (file, _("  --minor-subsystem-version <number> Set minimum required OS subsystem revision\n"));
  fprintf (file, _("  --section-alignment <size>         Set section alignment\n"));
  fprintf (file, _("  --stack <size>                     Set size of the initial stack\n"));
  fprintf (file, _("  --subsystem <name>[:<version>]     Set required OS subsystem [& version]\n"));
  fprintf (file, _("  --support-old-code                 Support interworking with old code\n"));
}

static void
set_pe_name (name, val)
     char *name;
     long val;
{
  int i;
  /* Find the name and set it. */
  for (i = 0; init[i].ptr; i++)
    {
      if (strcmp (name, init[i].symbol) == 0)
	{
	  init[i].value = val;
	  init[i].inited = 1;
	  return;
	}
    }
  abort();
}


static void
set_pe_subsystem ()
{
  const char *sver;
  int len;
  int i;
  static const struct 
    {
      const char *name;
      const int value;
      const char *entry;
    }
  v[] =
    {
      { "native", 1, "_NtProcessStartup" },
      { "windows", 2, "_WinMainCRTStartup" },
      { "console", 3, "_mainCRTStartup" },
#if 0
      /* The Microsoft linker does not recognize this.  */
      { "os2", 5, "" },
#endif
      { "posix", 7, "___PosixProcessStartup"},
      { 0, 0, 0 }
    };

  sver = strchr (optarg, ':');
  if (sver == NULL)
    len = strlen (optarg);
  else
    {
      char *end;

      len = sver - optarg;
      set_pe_name ("__major_subsystem_version__",
		   strtoul (sver + 1, &end, 0));
      if (*end == '.')
	set_pe_name ("__minor_subsystem_version__",
		     strtoul (end + 1, &end, 0));
      if (*end != '\0')
	einfo (_("%P: warning: bad version number in -subsystem option\n"));
    }

  for (i = 0; v[i].name; i++)
    {
      if (strncmp (optarg, v[i].name, len) == 0
	  && v[i].name[len] == '\0')
	{
	  set_pe_name ("__subsystem__", v[i].value);

	  lang_add_entry (v[i].entry, 1);

	  return;
	}
    }
  
  einfo (_("%P%F: invalid subsystem type %s\n"), optarg);
}



static void
set_pe_value (name)
     char *name;
     
{
  char *end;
  
  set_pe_name (name,  strtoul (optarg, &end, 0));
  
  if (end == optarg)
    einfo (_("%P%F: invalid hex number for PE parameter '%s'\n"), optarg);

  optarg = end;
}

static void
set_pe_stack_heap (resname, comname)
     char *resname;
     char *comname;
{
  set_pe_value (resname);
  
  if (*optarg == ',')
    {
      optarg++;
      set_pe_value (comname);
    }
  else if (*optarg)
    einfo (_("%P%F: strange hex info for PE parameter '%s'\n"), optarg);
}



static int
gld_${EMULATION_NAME}_parse_args(argc, argv)
     int argc;
     char **argv;
{
  int longind;
  int optc;
  int prevoptind = optind;
  int prevopterr = opterr;
  int wanterror;
  static int lastoptind = -1;

  if (lastoptind != optind)
    opterr = 0;
  wanterror = opterr;

  lastoptind = optind;

  optc = getopt_long_only (argc, argv, "-", longopts, &longind);
  opterr = prevopterr;

  switch (optc)
    {
    default:
      if (wanterror)
	xexit (1);
      optind =  prevoptind;
      return 0;

    case OPTION_BASE_FILE:
      link_info.base_file = (PTR) fopen (optarg, FOPEN_WB);
      if (link_info.base_file == NULL)
	{
	  /* xgettext:c-format */
	  fprintf (stderr, _("%s: Can't open base file %s\n"),
		   program_name, optarg);
	  xexit (1);
	}
      break;

      /* PE options */
    case OPTION_HEAP: 
      set_pe_stack_heap ("__size_of_heap_reserve__", "__size_of_heap_commit__");
      break;
    case OPTION_STACK: 
      set_pe_stack_heap ("__size_of_stack_reserve__", "__size_of_stack_commit__");
      break;
    case OPTION_SUBSYSTEM:
      set_pe_subsystem ();
      break;
    case OPTION_MAJOR_OS_VERSION:
      set_pe_value ("__major_os_version__");
      break;
    case OPTION_MINOR_OS_VERSION:
      set_pe_value ("__minor_os_version__");
      break;
    case OPTION_MAJOR_SUBSYSTEM_VERSION:
      set_pe_value ("__major_subsystem_version__");
      break;
    case OPTION_MINOR_SUBSYSTEM_VERSION:
      set_pe_value ("__minor_subsystem_version__");
      break;
    case OPTION_MAJOR_IMAGE_VERSION:
      set_pe_value ("__major_image_version__");
      break;
    case OPTION_MINOR_IMAGE_VERSION:
      set_pe_value ("__minor_image_version__");
      break;
    case OPTION_FILE_ALIGNMENT:
      set_pe_value ("__file_alignment__");
      break;
    case OPTION_SECTION_ALIGNMENT:
      set_pe_value ("__section_alignment__");
      break;
    case OPTION_DLL:
      set_pe_name ("__dll__", 1);
      break;
    case OPTION_IMAGE_BASE:
      set_pe_value ("__image_base__");
      break;
    case OPTION_SUPPORT_OLD_CODE:
      support_old_code = 1;
      break;
    }
  return 1;
}

/* Assign values to the special symbols before the linker script is
   read.  */

static void
gld_${EMULATION_NAME}_set_symbols ()
{
  /* Run through and invent symbols for all the
     names and insert the defaults. */
  int j;
  lang_statement_list_type *save;

  if (!init[IMAGEBASEOFF].inited)
    {
      if (link_info.relocateable)
	init[IMAGEBASEOFF].value = 0;
      else if (init[DLLOFF].value)
	init[IMAGEBASEOFF].value = NT_DLL_IMAGE_BASE;
      else
	init[IMAGEBASEOFF].value = NT_EXE_IMAGE_BASE;
    }

  /* Don't do any symbol assignments if this is a relocateable link.  */
  if (link_info.relocateable)
    return;

  /* Glue the assignments into the abs section */
  save = stat_ptr;

  stat_ptr = &(abs_output_section->children);

  for (j = 0; init[j].ptr; j++)
    {
      long val = init[j].value;
      lang_add_assignment (exp_assop ('=' ,init[j].symbol, exp_intop (val)));
      if (init[j].size == sizeof(short))
	*(short *)init[j].ptr = val;
      else if (init[j].size == sizeof(int))
	*(int *)init[j].ptr = val;
      else if (init[j].size == sizeof(long))
	*(long *)init[j].ptr = val;
      /* This might be a long long or other special type.  */
      else if (init[j].size == sizeof(bfd_vma))
	*(bfd_vma *)init[j].ptr = val;
      else	abort();
    }
  /* Restore the pointer. */
  stat_ptr = save;
  
  if (pe.FileAlignment >
      pe.SectionAlignment)
    {
      einfo (_("%P: warning, file alignment > section alignment.\n"));
    }
}

/* This is called after the linker script and the command line options
   have been read.  */

static void
gld_${EMULATION_NAME}_after_parse ()
{
  /* The Windows libraries are designed for the linker to treat the
     entry point as an undefined symbol.  Otherwise, the .obj that
     defines mainCRTStartup is brought in because it is the first
     encountered in libc.lib and it has other symbols in it which will
     be pulled in by the link process.  To avoid this, we act as
     though the user specified -u with the entry point symbol.

     This function is called after the linker script and command line
     options have been read, so at this point we know the right entry
     point.  This function is called before the input files are
     opened, so registering the symbol as undefined will make a
     difference.  */

  ldlang_add_undef (entry_symbol);
}

static void
gld_${EMULATION_NAME}_after_open ()
{
  /* Pass the wacky PE command line options into the output bfd.
     FIXME: This should be done via a function, rather than by
     including an internal BFD header.  */
  
  if (!coff_data (output_bfd)->pe)
    einfo (_("%F%P: PE operations on non PE file.\n"));

  pe_data (output_bfd)->pe_opthdr = pe;
  pe_data (output_bfd)->dll = init[DLLOFF].value;

#ifdef TARGET_IS_armpe
  {
    /* Find a BFD that can hold the interworking stubs.  */
    LANG_FOR_EACH_INPUT_STATEMENT (is)
      {
	if (bfd_arm_get_bfd_for_interworking (is->the_bfd, & link_info))
	  break;
      }
  }
#endif
}

static void  
gld_${EMULATION_NAME}_before_allocation()
{
#ifdef TARGET_IS_ppcpe
  /* Here we rummage through the found bfds to collect toc information */
  {
    LANG_FOR_EACH_INPUT_STATEMENT (is)
      {
	if (!ppc_process_before_allocation (is->the_bfd, &link_info))
	  {
	    /* xgettext:c-format */
	    einfo (_("Errors encountered processing file %s\n"), is->filename);
	  }
      }
  }

  /* We have seen it all. Allocate it, and carry on */
  ppc_allocate_toc_section (&link_info);
#endif /* TARGET_IS_ppcpe */

#ifdef TARGET_IS_armpe
  /* FIXME: we should be able to set the size of the interworking stub
     section.

     Here we rummage through the found bfds to collect glue
     information.  FIXME: should this be based on a command line
     option?  krk@cygnus.com */
  {
    LANG_FOR_EACH_INPUT_STATEMENT (is)
      {
	if (! bfd_arm_process_before_allocation
	    (is->the_bfd, & link_info, support_old_code))
	  {
	    /* xgettext:c-format */
	    einfo (_("Errors encountered processing file %s for interworking"),
		   is->filename);
	  }
      }
  }

  /* We have seen it all. Allocate it, and carry on */
  bfd_arm_allocate_interworking_sections (& link_info);
#endif /* TARGET_IS_armpe */
}

/* Place an orphan section.

   We use this to put sections in a reasonable place in the file, and
   to ensure that they are aligned as required.

   We handle grouped sections here as well.  A section named .foo$nn
   goes into the output section .foo.  All grouped sections are sorted
   by name.

   Grouped sections for the default sections are handled by the
   default linker script using wildcards, and are sorted by
   sort_sections.  */

static asection *hold_section;
static char *hold_section_name;
static lang_output_section_statement_type *hold_use;
static lang_output_section_statement_type *hold_text;
static lang_output_section_statement_type *hold_rdata;
static lang_output_section_statement_type *hold_data;
static lang_output_section_statement_type *hold_bss;

/* Place an orphan section.  We use this to put random SHF_ALLOC
   sections in the right segment.  */

/*ARGSUSED*/
static boolean
gld_${EMULATION_NAME}_place_orphan (file, s)
     lang_input_statement_type *file;
     asection *s;
{
  const char *secname;
  char *dollar;

  if ((s->flags & SEC_ALLOC) == 0)
    return false;

  secname = bfd_get_section_name (s->owner, s);

  /* Look through the script to see where to place this section.  */

  hold_section = s;

  hold_section_name = xstrdup (secname);
  dollar = strchr (hold_section_name, '$');
  if (dollar != NULL)
    *dollar = '\0';

  hold_use = NULL;
  lang_for_each_statement (gld${EMULATION_NAME}_place_section);

  if (hold_use == NULL)
    {
      lang_output_section_statement_type *place;
      char *outsecname;
      asection *snew, **pps;
      lang_statement_list_type *old;
      lang_statement_list_type add;
      etree_type *address;

      /* Try to put the new output section in a reasonable place based
	 on the section name and section flags.  */
      place = NULL;
      if ((s->flags & SEC_HAS_CONTENTS) == 0
	  && hold_bss != NULL)
	place = hold_bss;
      else if ((s->flags & SEC_READONLY) == 0
	       && hold_data != NULL)
	place = hold_data;
      else if ((s->flags & SEC_CODE) == 0
	       && (s->flags & SEC_READONLY) != 0
	       && hold_rdata != NULL)
	place = hold_rdata;
      else if ((s->flags & SEC_READONLY) != 0
	       && hold_text != NULL)
	place = hold_text;

      /* Choose a unique name for the section.  This will be needed if
	 the same section name appears in the input file with
	 different loadable or allocateable characteristics.  */
      outsecname = xstrdup (hold_section_name);
      if (bfd_get_section_by_name (output_bfd, outsecname) != NULL)
	{
	  unsigned int len;
	  char *newname;
	  unsigned int i;

	  len = strlen (outsecname);
	  newname = xmalloc (len + 5);
	  strcpy (newname, outsecname);
	  i = 0;
	  do
	    {
	      sprintf (newname + len, "%d", i);
	      ++i;
	    }
	  while (bfd_get_section_by_name (output_bfd, newname) != NULL);

	  free (outsecname);
	  outsecname = newname;
	}

      /* We don't want to free OUTSECNAME, as it may get attached to
	 the output section statement.  */

      /* Create the section in the output file, and put it in the
	 right place.  This shuffling is to make the output file look
	 neater.  */
      snew = bfd_make_section (output_bfd, outsecname);
      if (snew == NULL)
	einfo ("%P%F: output format %s cannot represent section called %s\n",
	       output_bfd->xvec->name, outsecname);
      if (place != NULL && place->bfd_section != NULL)
	{
	  for (pps = &output_bfd->sections; *pps != snew; pps = &(*pps)->next)
	    ;
	  *pps = snew->next;
	  snew->next = place->bfd_section->next;
	  place->bfd_section->next = snew;
	}

      /* Start building a list of statements for this section.  */
      old = stat_ptr;
      stat_ptr = &add;
      lang_list_init (stat_ptr);

      if (link_info.relocateable)
	address = NULL;
      else
	{
	  /* All sections in an executable must be aligned to a page
	     boundary.  */
	  address = exp_unop (ALIGN_K,
			      exp_nameop (NAME, "__section_alignment__"));
	}

      lang_enter_output_section_statement (outsecname, address, 0,
					   (bfd_vma) 0,
					   (etree_type *) NULL,
					   (etree_type *) NULL,
					   (etree_type *) NULL);

      hold_use = lang_output_section_statement_lookup (outsecname);

      lang_leave_output_section_statement
	((bfd_vma) 0, "*default*",
	 (struct lang_output_section_phdr_list *) NULL);

      /* Now stick the new statement list right after PLACE.  */
      if (place != NULL)
	{
	  *add.tail = place->header.next;
	  place->header.next = add.head;
	}

      stat_ptr = old;
    }

  if (dollar == NULL)
    wild_doit (&hold_use->children, s, hold_use, file);
  else
    {
      lang_statement_union_type **pl;
      boolean found_dollar;
      lang_statement_list_type list;

      /* The section name has a '$'.  Sort it with the other '$'
         sections.  */

      found_dollar = false;
      for (pl = &hold_use->children.head; *pl != NULL; pl = &(*pl)->next)
	{
	  lang_input_section_type *ls;
	  const char *lname;

	  if ((*pl)->header.type != lang_input_section_enum)
	    continue;

	  ls = &(*pl)->input_section;

	  lname = bfd_get_section_name (ls->ifile->the_bfd, ls->section);
	  if (strchr (lname, '$') == NULL)
	    {
	      if (found_dollar)
		break;
	    }
	  else
	    {
	      found_dollar = true;
	      if (strcmp (secname, lname) < 0)
		break;
	    }
	}

      lang_list_init (&list);
      wild_doit (&list, s, hold_use, file);
      ASSERT (list.head != NULL && list.head->next == NULL);

      list.head->next = *pl;
      *pl = list.head;
    }

  free (hold_section_name);

  return true;
}

static void
gld${EMULATION_NAME}_place_section (s)
     lang_statement_union_type *s;
{
  lang_output_section_statement_type *os;

  if (s->header.type != lang_output_section_statement_enum)
    return;

  os = &s->output_section_statement;

  if (strcmp (os->name, hold_section_name) == 0
      && os->bfd_section != NULL
      && ((hold_section->flags & (SEC_LOAD | SEC_ALLOC))
	  == (os->bfd_section->flags & (SEC_LOAD | SEC_ALLOC))))
    hold_use = os;

  if (strcmp (os->name, ".text") == 0)
    hold_text = os;
  else if (strcmp (os->name, ".rdata") == 0)
    hold_rdata = os;
  else if (strcmp (os->name, ".data") == 0)
    hold_data = os;
  else if (strcmp (os->name, ".bss") == 0)
    hold_bss = os;
}

static char *
gld_${EMULATION_NAME}_get_script(isfile)
     int *isfile;
EOF
# Scripts compiled in.
# sed commands to quote an ld script as a C string.
sc="-f ${srcdir}/emultempl/stringify.sed"

cat >>e${EMULATION_NAME}.c <<EOF
{			     
  *isfile = 0;

  if (link_info.relocateable == true && config.build_constructors == true)
    return
EOF
sed $sc ldscripts/${EMULATION_NAME}.xu                     >> e${EMULATION_NAME}.c
echo '  ; else if (link_info.relocateable == true) return' >> e${EMULATION_NAME}.c
sed $sc ldscripts/${EMULATION_NAME}.xr                     >> e${EMULATION_NAME}.c
echo '  ; else if (!config.text_read_only) return'         >> e${EMULATION_NAME}.c
sed $sc ldscripts/${EMULATION_NAME}.xbn                    >> e${EMULATION_NAME}.c
echo '  ; else if (!config.magic_demand_paged) return'     >> e${EMULATION_NAME}.c
sed $sc ldscripts/${EMULATION_NAME}.xn                     >> e${EMULATION_NAME}.c
echo '  ; else return'                                     >> e${EMULATION_NAME}.c
sed $sc ldscripts/${EMULATION_NAME}.x                      >> e${EMULATION_NAME}.c
echo '; }'                                                 >> e${EMULATION_NAME}.c

cat >>e${EMULATION_NAME}.c <<EOF


struct ld_emulation_xfer_struct ld_${EMULATION_NAME}_emulation = 
{
  gld_${EMULATION_NAME}_before_parse,
  syslib_default,
  hll_default,
  gld_${EMULATION_NAME}_after_parse,
  gld_${EMULATION_NAME}_after_open,
  after_allocation_default,
  set_output_arch_default,
  ldemul_default_target,
  gld_${EMULATION_NAME}_before_allocation,
  gld_${EMULATION_NAME}_get_script,
  "${EMULATION_NAME}",
  "${OUTPUT_FORMAT}",
  NULL, /* finish */
  NULL, /* create output section statements */
  NULL, /* open dynamic archive */
  gld_${EMULATION_NAME}_place_orphan,
  gld_${EMULATION_NAME}_set_symbols,
  gld_${EMULATION_NAME}_parse_args,
  NULL, /* unrecognised file */
  gld_${EMULATION_NAME}_list_options
};
EOF
