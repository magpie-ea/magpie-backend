// We import the CSS which is extracted to its own file by esbuild.
// Remove this line if you add a your own CSS build pipeline (e.g postcss).
import '../css/app.css';

// webpack automatically bundles all modules in your
// entry points. Those entry points can be configured
// in "webpack.config.js".
//
// Import deps with the dep name or local files with a relative path, for example:
//
// Note: I'm not actually using socket on the frontend of this Phoenix app itself.
//     import {Socket} from "phoenix"
// import socket from './socket';
//
import 'phoenix_html';

// From https://medium.com/@chipdean/phoenix-array-input-field-implementation-7ec0fe0949d
window.onload = () => {
  const removeElement = ({ target }) => {
    let el = document.getElementById(target.dataset.id);
    let li = el.parentNode;
    li.parentNode.removeChild(li);
  };
  Array.from(document.querySelectorAll('.remove-form-field')).forEach((el) => {
    el.onclick = (e) => {
      removeElement(e);
    };
  });
  Array.from(document.querySelectorAll('.add-form-field')).forEach((el) => {
    el.onclick = ({ target: { dataset } }) => {
      let container = document.getElementById(dataset.container);
      let index = container.dataset.index;
      let newRow = dataset.prototype;
      container.insertAdjacentHTML(
        'beforeend',
        newRow.replace(/__name__/g, index)
      );
      container.dataset.index = parseInt(container.dataset.index) + 1;
      container.querySelector('a.remove-form-field').onclick = (e) => {
        removeElement(e);
      };
    };
  });

  const toggleHide = function (checkbox, formGroup) {
    if (checkbox.checked) {
      formGroup.classList.remove('hide');
    } else {
      formGroup.classList.add('hide');
    }
  };

  if (document.querySelector('#dynamic-experiment-checkbox')) {
    const dynamicExperimentCheckbox = document.getElementById(
      'dynamic-experiment-checkbox'
    );
    const dynamicExperimentFormGroup = document.getElementById(
      'dynamic-experiment-form-group'
    );
    toggleHide(dynamicExperimentCheckbox, dynamicExperimentFormGroup);
    dynamicExperimentCheckbox.onchange = () => {
      toggleHide(dynamicExperimentCheckbox, dynamicExperimentFormGroup);
    };
  }

  if (document.querySelector('#interactive-experiment-checkbox')) {
    const interactiveExperimentCheckbox = document.getElementById(
      'interactive-experiment-checkbox'
    );
    const interactiveExperimentFormGroup = document.getElementById(
      'interactive-experiment-form-group'
    );
    toggleHide(interactiveExperimentCheckbox, interactiveExperimentFormGroup);
    interactiveExperimentCheckbox.onchange = () => {
      toggleHide(interactiveExperimentCheckbox, interactiveExperimentFormGroup);
    };
  }
};
