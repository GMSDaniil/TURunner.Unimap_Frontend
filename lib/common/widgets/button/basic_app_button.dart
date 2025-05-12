import 'package:auth_app/common/bloc/button/button_state_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../bloc/button/button_state.dart';

class BasicAppButton extends StatelessWidget {
  final VoidCallback onPressed;
  final String title;
  final bool isEnabled;
  final double? height;
  final double? width;
  const BasicAppButton({
    required this.onPressed,
    this.title = '',
    this.isEnabled = true,
    this.height,
    this.width,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ButtonStateCubit, ButtonState>(
      builder: (context, state) {
        if (state is ButtonLoadingState) {
          return _loading(context);
        }
        return _initial(context);
      },
    );
  }

  Widget _loading(BuildContext context) {
    return ElevatedButton(
      onPressed: null,
      style: ElevatedButton.styleFrom(
        disabledBackgroundColor: Colors.grey,
        minimumSize: Size(
          width ?? MediaQuery.of(context).size.width,
          height ?? 60,
        ),
      ),
      child: const CircularProgressIndicator(color: Colors.white),
    );
  }

  Widget _initial(BuildContext context) {
    return GestureDetector(
      onTap: isEnabled ? onPressed : null,
      child: Container(
        width: width ?? MediaQuery.of(context).size.width,
        height: height ?? 60,
        decoration: BoxDecoration(
          gradient:
              isEnabled
                  ? const LinearGradient(
                    colors: [Color(0xFF833AB4), Color(0xFFFF5E3A)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  )
                  : const LinearGradient(
                    colors: [Color(0xFF833AB4), Color(0xFFFF5E3A)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            if (isEnabled)
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                offset: const Offset(0, 5),
                blurRadius: 15,
              ),
          ],
        ),
        alignment: Alignment.center,
        child: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}
