                                        #! /usr/bin/env python2.3
# vim:sw=8:ts=8:et:nowrap

import os
import datetime
import re
import sys
import urllib
import string

import miscfuncs
import difflib
import mx.DateTime

from xmlfilewrite import WriteXMLHeader
import newlabministers2003_10_15

toppath = miscfuncs.toppath
chggdir = os.path.join(toppath, "chggpages")
sxml = os.path.join(toppath, "scrapedxml")
chggxml = os.path.join(sxml, "chggxml")
chgtmp = os.path.join(toppath, "tempchgg.xml")

if not os.path.isdir(chggxml):
	os.mkdir(chggxml)

uniqgovposns = ["Prime Minister",
				"Chancellor of the Exchequer",
				"Lord Steward",
				"Treasurer of Her Majesty's Household",
				"Chancellor of the Duchy of Lancaster",
				"President of the Council",
				"Parliamentary Secretary to the Treasury",
				"Second Church Estates Commissioner",
				"Chief Secretary",
				"Advocate General for Scotland",
				"Deputy Chief Whip (House of Lords)",
				"Vice Chamberlain",
				"Attorney General",
				"Chief Whip (House of Lords)",
				"Lord Privy Seal",
				"Solicitor General",
				"Economic Secretary",
				"Financial Secretary",
				"Lord Chamberlain",
				"Comptroller",
				"Deputy Prime Minister",
				"Paymaster General",
				"Master of the Horse",
				]

govposns = ["Secretary of State",
			"Minister without Portfolio",
			"Minister of State",
			"Parliamentary Secretary",
			"Parliamentary Under-Secretary",
			"Assistant Whip",
			"Lords Commissioner",
			"Lords in Waiting",
			"Baronesses in Waiting",
			 ]

govdepts = ["Department of Health",
			"HM Treasury",
			"HM Household",
			"Home Office",
			"Cabinet Office",
			"Privy Council Office",
			"Ministry of Defence",
			"Department for Environment, Food and Rural Affairs",
			"Department for International Development",
			"Department for Culture, Media & Sport",
			"Department for Constitutional Affairs",
			"Department for Education and Skills",
			"Office of the Deputy Prime Minister",
			"Department for Transport",
			"Department for Work and Pensions",
			"Northern Ireland Office",
			"Law Officers' Department",
			"Department of Trade and Industry",
			"House of Commons",
			"Foreign & Commonwealth Office",
			"No Department",
			]

renampos = re.compile("<td><b>([^,]*),\s*([^<]*)</b></td><td>([^,<]*)(?:,\s*([^<]*))?(?:</td>)?\s*$(?i)")

class protooffice:
	def __init__(self, lsdatet, e, deptno):  # department number to extract multiple departments
		self.sdatet = lsdatet

		nampos = renampos.match(e)
		self.lasname = nampos.group(1)
		self.froname = nampos.group(2)
		pos = nampos.group(3)
		dept = nampos.group(4) or "No Department"

		# separate out the departments if more than one
		if dept not in govdepts:
			self.depts = None

			# go through and try to match <dept> + " and "
			for gd in govdepts:
				dept0 = dept[:len(gd)]
				if (gd == dept0) and (dept[len(gd):len(gd) + 5] == " and "):
					dept1 = dept[len(gd) + 5:]

					# we're trying to split these strings up, but it's pretty rigid
					if dept1 in govdepts:
						self.depts = [ (pos, dept0), (pos, dept1) ]
						break
					pd1 = re.match("([^,]+),\s*(.+)$", dept1)
					if pd1 and pd1.group(2) in govdepts:
						self.depts = [ (pos, dept0), (pd1.group(1), pd1.group(2)) ]
						break
					print "Attempted match on", dept0

			if not self.depts:
				print "No match with", dept

		else:
			self.depts = [ (pos, dept) ]


		# map down to the department for this record
		self.pos = self.depts[deptno][0]
		self.dept = self.depts[deptno][1]

	# do the xml thing
	def WriteXML(self, fout):
		fout.write('<minister-post name="%s %s"\n' % (self.froname, self.lasname))
		fout.write('\tdept="%s" position="%s"\n' % (self.dept, self.pos))
		fout.write('\tfromdate="%s" fromtime="%s"\n' % self.sdatetstart)
		fout.write('\ttodate="%s" totime="%s"\n' % (self.bopen and ("9999-99-99", "99:99") or self.sdatetend))
		fout.write('\tsource="chgpages"/>\n')
		fout.write('/>\n')

	# turns the protooffice into a part of a chain
	def SetChainFront(self, fn):
		self.sdatetstart = self.sdatet
		self.sdatetend = self.sdatet
		self.fn = fn
		self.bopen = True

	def SetChainBack(self, sdatet):
		self.sdatetend = sdatet  # when we close it, it brings it up to the day the file changed
		self.bopen = False

	# this helps us chain the offices
	def StickChain(self, nextrec, fn):
		assert self.sdatetend < nextrec.sdatet
		assert self.bopen

		if (self.lasname == nextrec.lasname) and (self.froname == nextrec.froname) and (self.dept == nextrec.dept):
			self.sdatetend = nextrec.sdatet
			self.fn = fn
			return True
		return False


def ParsePage(fr):

	# extract the updated date and time
	frupdated = re.search('<td class="lastupdated">\s*Updated (.*?)&nbsp;(.*?)\s*</td>', fr)
	lsudate = re.match("(\d\d)/(\d\d)/(\d\d)$", frupdated.group(1))
	y2k = int(lsudate.group(3)) < 50 and "20" or "19"
	sudate = "%s%s-%s-%s" % (y2k, lsudate.group(3), lsudate.group(2), lsudate.group(1))
	sutime = frupdated.group(2)

	# extract the date on the document
	frdate = re.search(">Her Majesty's Government at\s+(.*?)\s*<", fr)
	msdate = mx.DateTime.DateTimeFrom(frdate.group(1)).date

	assert msdate == sudate   # is it always posted up on the day it is announced?

	sdate = msdate
	stime = sutime	# or midnight if not posted properly to match the msdate

	# extract the alphabetical list
	alphl = re.search("ALPHABETICAL LIST OF HM GOVERNMENT([\s\S]*?)</table>", fr).group(1)
	lst = re.split("</?tr>(?i)", alphl)

	# match the name form on each entry
	#<TD><B>Abercorn, Duke of</B></TD><TD>Lord Steward, HM Household</TD>

	res = [ ]

	luniqgov = uniqgovposns[:]
	for e1 in lst:
		e = e1.strip()
		if re.match("(?:<[^<]*>|\s)*$", e):
			continue

		# multiple entry of departments (simple inefficient method)
		for deptno in range(3):  # at most 3 offices at a time, we'll handle
			ec = protooffice((sdate, stime), e, deptno)

			# prove we've got all the posts
			if ec.pos not in govposns:
				if ec.pos in luniqgov:
					luniqgov.remove(ec.pos)
				else:
					print "Unnaccounted govt position", ec.pos

			res.append(ec)

			if len(ec.depts) == deptno + 1:
				break

	return (sdate, stime), res

# this goes through all the files and chains govt positions together
def ParseGovPostsChggdir():
	govpostdir = os.path.join(chggdir, "govposts")

	gps = os.listdir(govpostdir)
	gps.sort() # important to do in order of date

	chainprotos = [ ]
	for gp in gps:
		print "**** file", gp
		f = open(os.path.join(govpostdir, gp))
		fr = f.read()
		f.close()

		# get the protooffices from this file
		sdatet, proff = ParsePage(fr)

		# stick any chains we can
		proffnew = [ ]
		for prof in proff:
			bstuck = False
			for chainproto in chainprotos:
				if chainproto.bopen and (chainproto.fn != gp) and chainproto.StickChain(prof, gp):
					assert not bstuck
					bstuck = True
			if not bstuck:
				proffnew.append(prof)

		# close the chains that have not been stuck
		for chainproto in chainprotos:
			if chainproto.bopen and (chainproto.fn != gp):
				chainproto.SetChainBack(sdatet)
				#print "closing", chainproto.lasname

		# append on the new chains
		for prof in proffnew:
			prof.SetChainFront(gp)
			chainprotos.append(prof)

	#
	# everything is up to date now.
	# Close off the file
	#

	# set the present dates on those not closed
	for chainproto in chainprotos:
		if chainproto.bopen:
			chainproto.sdatetend = ("9999-99-99", "")

	return chainprotos




# main function that sticks it together
def ParseGovPosts():

	# get from our two sources (which unfortunately don't overlap, so they can't be merged)
	# We have a gap from 2003-10-15 to 2004-06-06 which needs filling !!!
	porres = newlabministers2003_10_15.ParseOldRecords()
	cpres = ParseGovPostsChggdir()

	fout = open(chgtmp, "w")
	WriteXMLHeader(fout)
	fout.write("<publicwhip>\n")

	for po in porres:
		po.WriteXML(fout)

	for cp in cpres:
		cp.WriteXML(fout)

	fout.write("</publicwhip>\n\n")
	fout.close();

	# copy file over to its place
	# ...

	return

	# output the result
	cblist = {}
	for chainproto in chainprotos:
		#print chainproto.sdatetstart, chainproto.sdatetend, chainproto.lasname
		if chainproto.dept not in cblist:
			cblist[chainproto.dept] = []
		if chainproto.pos not in cblist[chainproto.dept]:
			cblist[chainproto.dept].append(chainproto.pos)

	for c in cblist:
		print
		print c
		for d in cblist[c]:
			print "   ", d


