# Helper macros to convert spaces into question marks and back again
e :=
sp := $(e) $(e)
qs = $(subst ?,$(sp),$1)
sq = $(subst $(sp),?,$1)

# Get name of this Makefile (avoid getting word 0 and a starting space)
makefile_name := $(wordlist 1,1000,$(MAKEFILE_LIST))

# Get path of this Makefile
makefile_path := $(call qs,$(dir $(call sq,$(abspath $(call sq,$(makefile_name))))))

# Get path where the Application is
application_path := $(call qs,$(abspath $(call sq,$(makefile_path)..)))

# Change makefile_name to a relative path
makefile_name := $(subst $(call sq,$(application_path))/,,$(call sq,$(abspath $(call sq,$(makefile_name)))))

# Get relative path to makefile from application_path
makefile_path_relative := $(subst $(call sq,$(application_path))/,,$(call sq,$(abspath $(call sq,$(makefile_path)))))

# Get path to Middlewares
touchgfx_middlewares_path := gcc/Middlewares
cubemx_middlewares_path := Middlewares

# Get path to Drivers
Drivers_path := Drivers

# Get OS path
touchgfx_os_path := $(touchgfx_middlewares_path)/Third_Party/FreeRTOS
cubemx_os_path := $(cubemx_middlewares_path)/Third_Party/FreeRTOS

# Get identification of this system
ifeq ($(OS),Windows_NT)
UNAME := MINGW32_NT-6.2
else
UNAME := $(shell uname -s)
endif

float_abi := hardfp#softfp
board_name := RADHOUND_2
platform := cortex_m4f
#platform := cortex_m4f
cpp_compiler_options_local := -DUSE_HAL_DRIVER -DSTM32F405xx
#29xx
c_compiler_options_local := -DUSE_HAL_DRIVER -DSTM32F405xx
#29xx

.PHONY: all clean assets flash intflash

all: $(filter clean,$(MAKECMDGOALS))
all clean assets:
	@cd "$(application_path)" && $(MAKE) -r -f $(makefile_name) -s $(MFLAGS) _$@_

flash intflash: all
	@cd "$(application_path)" && $(MAKE) -r -f $(makefile_name) -s $(MFLAGS) _$@_

# Directories containing application-specific source and header files.
# Additional components can be added to this list. make will look for
# source files recursively in comp_name/src and setup an include directive
# for comp_name/include.
components := 	TouchGFX/gui \
				target \
				TouchGFX/generated/gui_generated \
				#Core/Src/ILI9341# Core/Src/MCP47FEB22
touchgfx_generator_components := TouchGFX/target TouchGFX/App
cubemx_components := Core Drivers/STM32F4xx_HAL_Driver

# Location of folder containing bmp/png files.
asset_images_input  := TouchGFX/assets/images

# Location of folder to search for ttf font files
asset_fonts_input  := TouchGFX/assets/fonts

# Location of folder where the texts.xlsx is placed
asset_texts_input  := TouchGFX/assets/texts

# Location of folder where video files are places
asset_videos_input := assets/videos

build_root_path := TouchGFX/build
object_output_path := $(build_root_path)/$(board_name)
binary_output_path := $(build_root_path)/bin

# Location of output folders where autogenerated code from assets is placed
asset_root_path := TouchGFX/generated
asset_images_output := $(asset_root_path)/images
asset_fonts_output := $(asset_root_path)/fonts
asset_texts_output := $(asset_root_path)/texts
asset_videos_output := $(asset_root_path)/videos

#include application specific configuration
include $(application_path)/TouchGFX/config/gcc/app.mk

# corrects TouchGFX Path
touchgfx_path := ${subst ../,,$(touchgfx_path)}

os_source_files := \
    $(cubemx_os_path)/Source/croutine.c \
    $(cubemx_os_path)/Source/event_groups.c \
    $(cubemx_os_path)/Source/list.c \
    $(cubemx_os_path)/Source/queue.c \
    $(cubemx_os_path)/Source/tasks.c \
    $(cubemx_os_path)/Source/timers.c \
    $(cubemx_os_path)/Source/CMSIS_RTOS_V2/cmsis_os2.c

os_include_paths := \
    $(cubemx_os_path)/Source/include \
    $(cubemx_os_path)/Source/CMSIS_RTOS_V2

os_source_files += \
    $(touchgfx_os_path)/Source/portable/MemMang/heap_4.c \
    $(touchgfx_os_path)/Source/portable/GCC/ARM_CM4F/port.c 

os_include_paths += \
    $(touchgfx_os_path)/Source/portable/GCC/ARM_CM4F 

ifeq ($(UNAME), Linux)
imageconvert_executable := $(touchgfx_path)/framework/tools/imageconvert/build/linux/imageconvert.out
fontconvert_executable := $(touchgfx_path)/framework/tools/fontconvert/build/linux/fontconvert.out
st_stm32cube_programmer := STM32_Programmer_CLI
else
imageconvert_executable := $(touchgfx_path)/framework/tools/imageconvert/build/win/imageconvert.out
fontconvert_executable := $(touchgfx_path)/framework/tools/fontconvert/build/win/fontconvert.out

include $(application_path)/gcc/include/cube_programmer.mk
# this AT comes with its own stldr

endif

target_executable := target.elf
target_hex := target.hex

########### Compiler options #################
# Defines the assembler binary and options. These are optional and only
# of relevance if the component includes source files with an
# extension of .asm.
assembler := arm-none-eabi-gcc
assembler_options += \
    -g  \
    -fno-exceptions\
    $(no_libs) -mthumb -mno-thumb-interwork  \
    -Wall

c_compiler := arm-none-eabi-gcc
c_compiler_options += \
    -g \
    -mthumb -fno-exceptions \
    -mno-thumb-interwork -std=gnu11 \
    $(no_libs) \
    -Os -fno-strict-aliasing -fdata-sections -ffunction-sections \
					--specs=nano.specs 

cpp_compiler := arm-none-eabi-g++
cpp_compiler_options += \
    -g3 -mthumb \
	$(no_libs) \
    -mno-thumb-interwork -fno-rtti -fno-exceptions  \
    -Os -fno-strict-aliasing -fdata-sections -ffunction-sections \
										--specs=nano.specs -std=gnu++14 -fstack-usage \
										-fno-threadsafe-statics -fno-use-cxa-atexit -femit-class-debug-always

linker := arm-none-eabi-g++
#linker_options += \
#    -mcpu=cortex-m4 -mthumb -specs=nosys.specs -specs=nano.specs -Wl,-Map=output.map -Wl,--gc-sections
linker_options += -g -Wl,-static -mthumb $(no_libs) -mno-thumb-interwork \
                  -fno-exceptions -specs=nosys.specs -fno-rtti \
                  -Os -fno-strict-aliasing -Wl,--gc-sections \
									--specs=nano.specs -Wl,--start-group \
									-lc -lm -lstdc++ -lsupc++ -Wl,--end-group \
									-Wl,--print-memory-usage



objcopy := arm-none-eabi-objcopy

archiver := arm-none-eabi-ar

strip := arm-none-eabi-strip

####################### Additional toolchain configuration for Cortex-M4f targets.##########################
float_options := -mfpu=fpv4-sp-d16
ifneq ("$(float_abi)","hard")
float_options += -mfloat-abi=softfp
else
float_options += -mfloat-abi=hard
endif

assembler_options += -mcpu=cortex-m4 -march=armv7e-m -Wno-psabi $(float_options) -DCORE_M4 -D__irq=""
c_compiler_options += -mcpu=cortex-m4 -march=armv7e-m  -Wno-psabi $(float_options) -DCORE_M4 -D__irq=""
cpp_compiler_options += -mcpu=cortex-m4 -march=armv7e-m -Wno-psabi $(float_options) -DCORE_M4 -D__irq=""
linker_options += -mcpu=cortex-m4 -march=armv7e-m -Wno-psabi $(float_options)

############################################################################################################
user_libs_src := 	Core/Lib/ILI9341 \
					Core/Lib/MCP47FEB22 \
					Core/Lib/MCP9808 \
					Core/Lib/SETTING \
					Core/Lib/EEPROM \


#include everything + specific vendor folders
framework_includes := $(touchgfx_path)/framework/include

#this needs to change when assset include folder changes.
all_components := $(components) \
	$(asset_fonts_output) \
	$(asset_images_output) \
	$(asset_texts_output) \
	$(asset_videos_output)

#keep framework include and source out of this mess! :)
include_paths := $(library_includes) \
    $(foreach comp, $(all_components), $(comp)/include) \
    $(foreach comp, $(cubemx_components), $(comp)/Inc) \
    $(foreach comp, $(touchgfx_generator_components), $(comp)/generated) \
    $(framework_includes) \
    $(touchgfx_middlewares_path) \
    $(cubemx_middlewares_path) \
    $(touchgfx_generator_components) \
	$(call find, $(user_libs_src), *.h)

source_paths = $(foreach comp, $(all_components), $(comp)/src) \
    $(foreach comp, $(cubemx_components), $(comp)/Src) \
    $(touchgfx_generator_components) \

# Finds files that matches the specified pattern. The directory list
# is searched recursively. It is safe to invoke this function with an
# empty list of directories.
#
# Param $(1): List of directories to search
# Param $(2): The file pattern to search for
define find
  $(foreach dir,$(1),$(foreach d,$(wildcard $(dir)/*),\
    $(call find,$(d),$(2))) $(wildcard $(dir)/$(strip $(2))))
endef
unexport find

fontconvert_ttf_lower_files := $(call find, $(asset_fonts_input), *.ttf)
fontconvert_ttf_upper_files := $(call find, $(asset_fonts_input), *.TTF)
fontconvert_otf_lower_files := $(call find, $(asset_fonts_input), *.otf)
fontconvert_otf_upper_files := $(call find, $(asset_fonts_input), *.OTF)
fontconvert_bdf_lower_files := $(call find, $(asset_fonts_input), *.bdf)
fontconvert_bdf_upper_files := $(call find, $(asset_fonts_input), *.BDF)
fontconvert_font_files := \
    $(fontconvert_ttf_lower_files) \
    $(fontconvert_ttf_upper_files) \
    $(fontconvert_otf_lower_files) \
    $(fontconvert_otf_upper_files) \
    $(fontconvert_bdf_lower_files) \
    $(fontconvert_bdf_upper_files)

source_files := $(call find, $(source_paths),*.cpp)

board_c_files += \
#    $(Drivers_path)/BSP/Components/stmpe811/stmpe811.c \
#    $(Drivers_path)/BSP/Components/ili9341/ili9341.c
				

board_cpp_files := \


board_include_paths := \
    Drivers/CMSIS/Device/ST/STM32F4xx/Include \
    Drivers/CMSIS/Include \
    Drivers/BSP \
    Middlewares/Third_Party/FreeRTOS/Source/CMSIS_RTOS_V2 \
    Middlewares/Third_Party/FreeRTOS/Source \
	Core/Lib/MCP47FEB22 \
	Core/Lib/ILI9341 \
	Core/Lib/MCP9808 \
	Core/Lib/SETTING \
	Core/Lib/EEPROM\
	Core/Inc/App \
	#MCP47FEB22/ \

#asm_source_files := gcc/startup_stm32f446retx.s
asm_source_files := gcc/startup_stm32f405rgtx.s

c_compiler_options +=
cpp_compiler_options +=

include_paths += platform/os $(board_include_paths) $(os_include_paths)


c_source_files := $(call find, $(source_paths),*.c) $(os_source_files) $(board_c_files) $(call find, $(user_libs_src),*.c)
source_files += $(board_cpp_files)


object_files := $(source_files) $(c_source_files)
# Start converting paths
object_files := $(object_files:$(touchgfx_path)/%.cpp=$(object_output_path)/touchgfx/%.o)
object_files := $(object_files:%.cpp=$(object_output_path)/%.o)
object_files := $(object_files:$(Middlewares_path)/%.c=$(object_output_path)/Middlewares/%.o)
object_files := $(object_files:$(Drivers_path)/%.c=$(object_output_path)/Drivers/%.o)
object_files := $(object_files:%.c=$(object_output_path)/%.o)

# Remove templates files
object_files := $(filter-out %template.o,$(object_files))

dependency_files := $(object_files:%.o=%.d)

object_asm_files := $(asm_source_files:%.s=$(object_output_path)/%.o)
object_asm_files := $(patsubst $(object_output_path)/%,$(object_output_path)/%,$(object_asm_files))

textconvert_script_path := $(touchgfx_path)/framework/tools/textconvert
textconvert_executable := $(call find, $(textconvert_script_path), *.rb)

videoconvert_script_path := $(touchgfx_path)/framework/tools/videoconvert
text_database := $(asset_texts_input)/texts.xml

ifeq ("$(float_abi)","hard")
libraries := touchgfx-float-abi-hard
else
libraries := touchgfx
endif
library_include_paths := $(touchgfx_path)/lib/core/$(platform)/gcc

.PHONY: _all_ _clean_ _assets_ _flash_ _intflash_ generate_assets build_executable

# Force linking each time
.PHONY: $(binary_output_path)/$(target_executable)

_all_: generate_assets


ifeq ($(shell find "$(application_path)" -wholename "$(application_path)/$(binary_output_path)/extflash.hex" -size +0c | wc -l | xargs echo),1)
_flash_: _extflash_
else
_flash_: _intflash_
endif

#_flash_: _intflash_

#include $(application_path)/gcc/include/flash_sections_int.mk
include $(application_path)/gcc/include/flash_sections_int_ext.mk

generate_assets: _assets_
	@$(MAKE) -f $(makefile_name) -r -s $(MFLAGS) build_executable
build_executable: $(binary_output_path)/$(target_executable)

$(binary_output_path)/$(target_executable): $(object_files) $(object_asm_files)
	@echo Linking $(@)
	@mkdir -p $(@D)
	@mkdir -p $(object_output_path)
	@$(file >$(build_root_path)/objects.tmp) $(foreach F,$(object_files),$(file >>$(build_root_path)/objects.tmp,$F))

#	$(info \
		#@$(linker) \
		#$(linker_options) -T $(makefile_path_relative)/STM32F446RETX_FLASH.ld -Wl,-Map=$(@D)/application.map $(linker_options_local) \
		#$(patsubst %,-L%,$(library_include_paths)) \
		#@$(build_root_path)/objects.tmp $(object_asm_files) -o $@ \
		#-Wl,--start-group $(patsubst %,-l%,$(libraries)) -Wl,--end-group \
	#@rm -f $(build_root_path)/objects.tmp\
	#@echo "Producing additional output formats..."\
	#@echo "  intflash.hex - Internal flash, hex"\
	#@$(objcopy) -O ihex $@ $(@D)/intflash.hex)
	

		#$(linker_options) -T $(makefile_path_relative)/STM32F446RETX_FLASH.ld -Wl,-Map=$(@D)/application.map $(linker_options_local) 
	@$(linker) \
		$(linker_options) -T $(makefile_path_relative)/STM32F405RGTX_FLASH.ld -Wl,-Map=$(@D)/application.map $(linker_options_local) \
		$(patsubst %,-L%,$(library_include_paths)) \
		@$(build_root_path)/objects.tmp $(object_asm_files) -o $@ \
		-Wl,--start-group $(patsubst %,-l%,$(libraries)) -Wl,--end-group
	@rm -f $(build_root_path)/objects.tmp
	@echo "Producing additional output formats..."
	@echo "  target.hex   - Combined internal+external hex"
	@$(objcopy) -O ihex $@ $(@D)/target.hex
	@echo "  intflash.elf - Internal flash, elf debug"
	@$(objcopy) $@ $(@D)/intflash.elf 2>/dev/null
	#@$(objcopy) --remove-section=ExtFlashSection --remove-section=FontFlashSection $@ $(@D)/intflash.elf 2>/dev/null
	@echo "  intflash.hex - Internal flash, hex"
#	@$(objcopy) -O ihex --remove-section=ExtFlashSection --remove-section=FontFlashSection $@ $(@D)/intflash.hex
	@$(objcopy) -O ihex  $@ $(@D)/intflash.hex
	@echo "  extflash.bin - External flash, binary"
	@$(objcopy) -O ihex --only-section=ExtFlashSection  --only-section=FontFlashSection $@ $(@D)/extflash.hex
	#@$(objcopy) -O binary --only-section=ExtFlashSection --only-section=FontFlashSection $@ $(@D)/extflash.bin

#	@echo "Producing additional output formats..."
	#@echo "  intflash.hex - Internal flash, hex"
	#@$(objcopy) -O ihex $@ $(@D)/intflash.hex

#		$(linker_options) -T $(makefile_path_relative)/STM32F446RETX_FLASH.ld -Wl,-Map=$(@D)/application.map $(linker_options_local) 
	$(info 	@$(linker) \
		$(linker_options) -T $(makefile_path_relative)/STM32F405RGTX_FLASH.ld -Wl,-Map=$(@D)/application.map $(linker_options_local) \
		$(patsubst %,-L%,$(library_include_paths)) \
		@$(build_root_path)/objects.tmp $(object_asm_files) -o $@ \
		-Wl,--start-group $(patsubst %,-l%,$(libraries)) -Wl,--end-group )
	$(info @$(objcopy) -O ihex $@ $(@D)/intflash.hex)


$(object_output_path)/touchgfx/%.o: $(touchgfx_path)/%.cpp TouchGFX/config/gcc/app.mk
	@echo Compiling $<
	@mkdir -p $(@D)
	@$(cpp_compiler) \
		-MMD -MP $(cpp_compiler_options) $(cpp_compiler_options_local) $(user_cflags) \
		$(patsubst %,-I%,$(include_paths)) \
		-c $< -o $@

$(object_output_path)/%.o: %.cpp TouchGFX/config/gcc/app.mk
	@echo Compiling $<
	@mkdir -p $(@D)
	@$(cpp_compiler) \
		-MMD -MP $(cpp_compiler_options) $(cpp_compiler_options_local) $(user_cflags) \
		$(patsubst %,-I%,$(include_paths)) \
		-c $< -o $@

$(object_output_path)/touchgfx/%.o: $(touchgfx_path)/%.c TouchGFX/config/gcc/app.mk
	@echo Compiling $<
	@mkdir -p $(@D)
	@$(c_compiler) \
		-MMD -MP $(c_compiler_options) $(c_compiler_options_local) $(user_cflags) \
		$(patsubst %,-I%,$(include_paths)) \
		-c $< -o $@

$(object_output_path)/%.o: %.c TouchGFX/config/gcc/app.mk
	@echo Compiling $<
	@mkdir -p $(@D)
	@$(c_compiler) \
		-MMD -MP $(c_compiler_options) $(c_compiler_options_local) $(user_cflags) \
		$(patsubst %,-I%,$(include_paths)) \
		-c $< -o $@

$(object_output_path)/%.o: %.s TouchGFX/config/gcc/app.mk
	@echo Compiling ASM $<
	@mkdir -p $(@D)
	@$(assembler) \
		$(assembler_options) \
		$(patsubst %,-I %,$(os_include_paths)) \
		-c $< -o $@

ifeq ($(MAKECMDGOALS),build_executable)
$(firstword $(dependency_files)): TouchGFX/config/gcc/app.mk
	@rm -rf $(object_output_path)
-include $(dependency_files)
endif

_assets_: BitmapDatabase TextKeysAndLanguages videos

.PHONY: BitmapDatabase TextKeysAndLanguages

BitmapDatabase:
	@$(imageconvert_executable) -r $(asset_images_input) -w $(asset_images_output)

TextKeysAndLanguages:
	@mkdir -p $(asset_texts_output)/include/texts
	@ruby $(textconvert_script_path)/main.rb $(text_database) $(fontconvert_executable) $(asset_fonts_output) $(asset_texts_output) $(asset_fonts_input) TouchGFX $(text_converter_options)

.PHONY: videos
videos:
	@ruby $(videoconvert_script_path)/videoconvert.rb $(asset_videos_input) $(asset_videos_output)

_clean_:
	@echo Cleaning
	@rm -rf $(build_root_path)
	# Do not remove gui_generated
	@rm -rf $(asset_images_output)
	@rm -rf $(asset_fonts_output)
	@rm -rf $(asset_texts_output)
	# Create directory to avoid error if it does not exist
	@mkdir -p $(asset_root_path)
	# Remove assets folder if it is empty (i.e. no gui_generated folder)
	@rmdir --ignore-fail-on-non-empty $(asset_root_path)


#######################################
# Print makefile variables
#######################################
print-%:
	@echo VARIABLE=$($*)