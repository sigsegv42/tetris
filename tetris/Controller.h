#ifndef INCLUDED_TETRIS_CONTROLLER
#define INCLUDED_TETRIS_CONTROLLER

#include <hookah/Window.h>
#include <command/CommandDirectory.h>
#include <input/KeyboardDevice.h>
#include <input/MouseDevice.h>
#include <gui/InputEventAdapter.h>

class TetrisScene;
class TetrisRenderer;

class Controller
{
	public:
		Controller();

		bool run();
		bool exec(const v3D::CommandInfo & command, const std::string & param);

	private:
		boost::shared_ptr<TetrisScene> scene_;
		boost::shared_ptr<TetrisRenderer> renderer_;
		boost::shared_ptr<Hookah::Window> window_;
		boost::shared_ptr<v3D::KeyboardDevice> keyboard_;
		boost::shared_ptr<v3D::MouseDevice> mouse_;
		v3D::CommandDirectory directory_;
		boost::shared_ptr<InputEventAdapter> listenerAdapter_;
};

#endif // INCLUDED_TETRIS_CONTROLLER
