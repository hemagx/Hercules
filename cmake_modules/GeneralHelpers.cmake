# This file is part of Hercules.
# http://herc.ws - http://github.com/HerculesWS/Hercules
#
# Copyright (C) 2026 Hercules Dev Team
#
# Hercules is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

# Appends a list of headers to global property ALL_HDRS with their absloute path
# _headers list of headers
function(add_header_all_list _headers)
  get_property(OLD_ALL_HDRS GLOBAL PROPERTY ALL_HDRS)
  foreach(_header IN LISTS _headers)
    list(APPEND OLD_ALL_HDRS "${CMAKE_CURRENT_SOURCE_DIR}/${_header}")
  endforeach()
  set_property(GLOBAL PROPERTY ALL_HDRS ${OLD_ALL_HDRS})
endfunction()

# Appends a list of headers to global property ALL_CONFIG_HDRS with their absloute path
# _headers list of headers
function(add_header_all_config_list _headers)
  get_property(OLD_ALL_CONFIG_HDRS GLOBAL PROPERTY ALL_CONFIG_HDRS)
  foreach(_header IN LISTS _headers)
    list(APPEND OLD_ALL_CONFIG_HDRS "${CMAKE_CURRENT_SOURCE_DIR}/${_header}")
  endforeach()
  set_property(GLOBAL PROPERTY ALL_CONFIG_HDRS ${OLD_ALL_CONFIG_HDRS})
endfunction()

