// We need to import the CSS so that webpack will load it.
// The MiniCssExtractPlugin is used to separate it out into
// its own CSS file.
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

  if (document.querySelector('#dynamic-experiment-checkbox')) {
    console.log('Asdfsadfgsdfg');

    const dynamicExperimentCheckbox = document.getElementById(
      'dynamic-experiment-checkbox'
    );
    const dynamicExperimentFormGroup = document.getElementById(
      'dynamic-experiment-form-group'
    );
    dynamicExperimentCheckbox.onchange = () => {
      console.log('asdf');
      if (dynamicExperimentCheckbox.checked) {
        dynamicExperimentFormGroup.classList.remove('hide');
      } else {
        dynamicExperimentFormGroup.classList.add('hide');
      }
    };
  }
};
