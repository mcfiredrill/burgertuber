defmodule OsfBridge.OsfParser do
  def parse(packet) when is_binary(packet) do
    <<time::float-64-little, id::signed-32-little, width::float-32-little, height::float-32-little,
      right_eye_open::float-32-little, left_eye_open::float-32-little,
      is_3d::size(8), fit_error::float-32-little,
      qx::float-32-little, qy::float-32-little, qz::float-32-little, qw::float-32-little,
      ex::float-32-little, ey::float-32-little, ez::float-32-little,
      tx::float-32-little, ty::float-32-little, tz::float-32-little,
      rest::binary>> = packet


    %{
      time: time,
      id: id,
      cam: %{width: width, height: height},
      rightEyeOpen: right_eye_open,
      leftEyeOpen: left_eye_open,
      "3d": is_3d,
      fitError: fit_error,
      quaternion: %{x: qx, y: qy, z: qz, w: qw},
      euler: %{x: ex, y: ey, z: ez},
      translation: %{x: tx, y: ty, z: tz},
      # rest: rest
    }
  end
end
