# Overview

Develop a skill that allows Claude to use the Hoogle tool (locally installed)
to retrieve documentation, matching types, and other information from
a local database.

This skill should be used by Claude to discover details of dependent libraries
for a given project; however, an expliciit command is also provided for use 
by the user. The command should take a natural language query, translate them
into something hoogle understands, and produce results.  

# Requirements

* Only provide a skill and a command; do not provide an MCP.
* DO NOT use hoogle as a server - only use the executable to query the local database
* Create wrapper scripts to make input/output from hoogle easy. Have hoogle
produce JSON output for easy parsing. Check that the local database has been generated; if not, create one
* Ship @hoogle.xml with the plugin, and make sure claude knows when to use it.

# Details

* Read @hoogle.xml to understand how to use hoogle.
* Verify that hoogle in  be on the path (and verify!)
* Write tests for various scenarios where Hooogle returns many results, no
results, single result. Add those to this repo but don't ship them.

# Development documentation

These docs will help you build the skill, but they are not be shipped with 
the plugin.

Read the following files to understand how to create a skill:

* ./plugins-reference.html
* ./claude-code.xml
* ./plugins.html
* ./settings.html
