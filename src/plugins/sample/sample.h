/**
 * This file is part of Hercules.
 * http://herc.ws - http://github.com/HerculesWS/Hercules
 *
 * Copyright (C) 2013-2025 Hercules Dev Team
 *
 * Hercules is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */
#ifndef PLUGIN_SAMPLE_SAMPLE_H
#define PLUGIN_SAMPLE_SAMPLE_H

// check is TESTVAR defined from custom compile flags
#ifndef TESTVAR
#error TESTVAR not defined
#endif

// check is TESTVAR2 defined to value 2 from custom compile flags
#if !(TESTVAR2 == 2)
#error TESTVAR2 not defined
#endif

#endif /* PLUGIN_SAMPLE_SAMPLE_H */
